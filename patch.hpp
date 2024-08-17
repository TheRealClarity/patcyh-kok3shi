/* patcyh - you should pronounce it like patch
 * Copyright (C) 2015-2016  Jay Freeman (saurik)
*/

/* GNU General Public License, Version 3 {{{ */
/*
 * Cydia is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License,
 * or (at your option) any later version.
 *
 * Cydia is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Cydia.  If not, see <http://www.gnu.org/licenses/>.
**/
/* }}} */

#ifndef PATCH_HPP
#define PATCH_HPP

#include <string>

#include <dlfcn.h>

#include <sys/mman.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <mach-o/loader.h>

#define LIBUICACHE "/usr/lib/libpatcyh.dylib"

static void *(*$memmem)(const void *, size_t, const void *, size_t) = reinterpret_cast<void *(*)(const void *, size_t, const void *, size_t)>(dlsym(RTLD_DEFAULT, "memmem"));

template <typename Header>
static bool PatchInstall(bool uninstall, void *data) {
    Header *header(reinterpret_cast<Header *>(data));

    load_command *command(reinterpret_cast<load_command *>(header + 1));
    for (size_t i(0); i != header->ncmds; ++i, command = reinterpret_cast<load_command *>(reinterpret_cast<uint8_t *>(command) + command->cmdsize)) {
        if (command->cmdsize > sizeof(Header) + header->sizeofcmds - (reinterpret_cast<uint8_t *>(command) - reinterpret_cast<uint8_t *>(header))) {
            fprintf(stderr, "load command is to long to fit in header\n");
            return false;
        }

        if (command->cmd != LC_LOAD_DYLIB)
            continue;

        dylib_command *load(reinterpret_cast<dylib_command *>(command));
        const char *name(reinterpret_cast<char *>(command) + load->dylib.name.offset);
        if (strcmp(name, LIBUICACHE) != 0)
            continue;

        if (!uninstall)
            return true;

        if (i != header->ncmds - 1) {
            fprintf(stderr, "load command not in final position %zd %u\n", i, header->ncmds);
            return false;
        }

        if (reinterpret_cast<uint8_t *>(command) + command->cmdsize != reinterpret_cast<uint8_t *>(header + 1) + header->sizeofcmds) {
            fprintf(stderr, "load command header size integrity fail\n");
            return false;
        }

        --header->ncmds;
        header->sizeofcmds -= command->cmdsize;
        memset(command, 0, command->cmdsize);

        return true;
    }

    if (reinterpret_cast<uint8_t *>(command) != reinterpret_cast<uint8_t *>(header + 1) + header->sizeofcmds) {
        fprintf(stderr, "load command header size integrity fail\n");
        return false;
    }

    if (uninstall)
        return true;

    dylib_command *load(reinterpret_cast<dylib_command *>(command));
    memset(load, 0, sizeof(*load));
    load->cmd = LC_LOAD_DYLIB;

    load->cmdsize = sizeof(*load) + sizeof(LIBUICACHE);
    load->cmdsize = (load->cmdsize + 15) / 16 * 16;
    memset(load + 1, 0, load->cmdsize - sizeof(*load));

    dylib *dylib(&load->dylib);
    dylib->name.offset = sizeof(*load);
    memcpy(load + 1, LIBUICACHE, sizeof(LIBUICACHE));

    ++header->ncmds;
    header->sizeofcmds += load->cmdsize;

    return true;
}

static bool Patch(const std::string &path, const std::string &service, bool uninstall, bool abort) {
    if (!abort && system("ldid --") != 0) {
        fprintf(stderr, "this package requires ldid to be installed\n");
        return false;
    }

    int fd(open(path.c_str(), O_RDWR));
    if (fd == -1)
        return false;

    struct stat stat;
    if (fstat(fd, &stat) == -1) {
        close(fd);
        return false;
    }

    size_t size(stat.st_size);
    void *data(mmap(NULL, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0));
    close(fd);
    if (data == MAP_FAILED)
        return false;

    bool changed(false);
    uint32_t magic(*reinterpret_cast<uint32_t *>(data));
    switch (magic) {
        case MH_MAGIC:
            changed = PatchInstall<mach_header>(uninstall, data);
            break;
        case MH_MAGIC_64:
            changed = PatchInstall<mach_header_64>(uninstall, data);
            break;
        default:
            fprintf(stderr, "unknown header magic on installd: %08x\n", magic);
            return false;
    }

    munmap(data, size);

    if (changed) {
        system(("ldid -s " + path + "").c_str());
        system(("cp -af " + path + " " + path + "_").c_str());
        system(("mv -f " + path + "_ " + path + "").c_str());
        system(("launchctl stop " + service + "").c_str());
    }

    return true;
}


static bool PatchInstall(bool uninstall, bool abort) {
    return Patch("/usr/libexec/installd", "com.apple.mobile.installd", uninstall, abort);
}

static bool PatchLaunch(bool uninstall, bool abort) {
    return Patch("/usr/libexec/lsd", "com.apple.lsd", uninstall, abort);
}

#endif//PATCH_HPP
