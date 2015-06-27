/* patcyh - you should pronounce it like patch
 * Copyright (C) 2015  Jay Freeman (saurik)
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

#include <Foundation/Foundation.h>

#include "patch.hpp"

int main(int argc, const char *argv[]) {
    if (argc < 2 || (
        strcmp(argv[1], "abort-install") != 0 &&
        strcmp(argv[1], "remove") != 0 &&
    true)) return 0;

    bool abort(strcmp(argv[1], "abort-install") == 0);

    NSAutoreleasePool *pool([[NSAutoreleasePool alloc] init]);

    if (!PatchInstall(true, abort))
        return 1;
    system("launchctl stop com.apple.mobile.installd");

    [pool release];
    return 0;
}
