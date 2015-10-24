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

#include <pthread.h>
#include <objc/runtime.h>
#include <Foundation/Foundation.h>

@class LSDXPCServer;

@interface MIFileManager
+ (MIFileManager *) defaultManager;
- (NSURL *) destinationOfSymbolicLinkAtURL:(NSURL *)url error:(NSError *)error;
@end

static Class $MIFileManager;

static pthread_key_t key_;

static NSArray *(*_MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$)(MIFileManager *self, SEL _cmd, NSURL *url, BOOL ignoring, NSError *error);

static NSArray *$MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$(MIFileManager *self, SEL _cmd, NSURL *url, BOOL ignoring, NSError *error) {
    MIFileManager *manager(reinterpret_cast<MIFileManager *>([$MIFileManager defaultManager]));
    NSURL *destiny([manager destinationOfSymbolicLinkAtURL:url error:NULL]);
    if (destiny == nil)
        return _MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$(self, _cmd, url, NO, error);

    NSArray *prefix([url pathComponents]);
    size_t skip([[destiny pathComponents] count]);
    NSMutableArray *items([NSMutableArray array]);
    for (NSURL *item in _MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$(self, _cmd, destiny, NO, error)) {
        NSArray *components([item pathComponents]);
        [items addObject:[NSURL fileURLWithPathComponents:[prefix arrayByAddingObjectsFromArray:[components subarrayWithRange:NSMakeRange(skip, [components count] - skip)]]]];
    }

    return items;
}

static NSString *(*_NSURL$path)(NSURL *self, SEL _cmd);

static NSString *$NSURL$path(NSURL *self, SEL _cmd) {
    NSString *path(_NSURL$path(self, _cmd));
    if (pthread_getspecific(key_) != NULL)
        path = [[path mutableCopy] autorelease];
    return path;
}

static NSRange (*_NSString$rangeOfString$options$)(NSString *self, SEL _cmd, NSString *value, NSStringCompareOptions options);

static NSRange $NSString$rangeOfString$options$(NSString *self, SEL _cmd, NSString *value, NSStringCompareOptions options) {
    do {
        if (pthread_getspecific(key_) == NULL)
            break;
        if (![value isEqualToString:@".app/"])
            break;

        char *real(realpath("/Applications", NULL));
        NSString *destiny([NSString stringWithUTF8String:real]);
        free(real);

        if ([destiny isEqualToString:@"/Applications"])
            break;

        destiny = [destiny stringByAppendingString:@"/"];
        if (![self hasPrefix:destiny])
            break;

        BOOL directory;
        if (![[NSFileManager defaultManager] fileExistsAtPath:self isDirectory:&directory])
            break;
        if (!directory)
            break;

        // the trailing / allows lsd to "restart" its verification attempt
        [(NSMutableString *) self setString:[NSString stringWithFormat:@"/Applications/%@/", [self substringFromIndex:[destiny length]]]];
    } while (false);

    return _NSString$rangeOfString$options$(self, _cmd, value, options);
}

static id (*_LSDXPCServer$canOpenURL$connection$)(LSDXPCServer *self, SEL _cmd, id url, id connection);

static id $LSDXPCServer$canOpenURL$connection$(LSDXPCServer *self, SEL _cmd, id url, id connection) {
    pthread_setspecific(key_, connection);
    @try {
        return _LSDXPCServer$canOpenURL$connection$(self, _cmd, url, connection);
    } @finally {
        pthread_setspecific(key_, NULL);
    }
}

__attribute__((__constructor__))
static void initialize() {
    pthread_key_create(&key_, NULL);

    $MIFileManager = objc_getClass("MIFileManager");

    if ($MIFileManager != Nil) {
        SEL sel(@selector(urlsForItemsInDirectoryAtURL:ignoringSymlinks:error:));
        if (Method method = class_getInstanceMethod($MIFileManager, sel)) {
            _MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$ = reinterpret_cast<NSArray *(*)(MIFileManager *, SEL, NSURL *, BOOL, NSError *)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(&$MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$));
        }
    }

    if (Class $NSURL = objc_getClass("NSURL")) {
        SEL sel(@selector(path));
        if (Method method = class_getInstanceMethod($NSURL, sel)) {
            _NSURL$path = reinterpret_cast<NSString *(*)(NSURL *, SEL)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(&$NSURL$path));
        }
    }

    if (Class $NSString = objc_getClass("NSString")) {
        SEL sel(@selector(rangeOfString:options:));
        if (Method method = class_getInstanceMethod($NSString, sel)) {
            _NSString$rangeOfString$options$ = reinterpret_cast<NSRange (*)(NSString *, SEL, NSString *, NSStringCompareOptions)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(&$NSString$rangeOfString$options$));
        }
    }

    if (Class $LSDXPCServer = objc_getClass("LSDXPCServer")) {
        SEL sel(@selector(canOpenURL:connection:));
        if (Method method = class_getInstanceMethod($LSDXPCServer, sel)) {
            _LSDXPCServer$canOpenURL$connection$ = reinterpret_cast<id (*)(LSDXPCServer *, SEL, id, id)>(method_getImplementation(method));
            method_setImplementation(method, reinterpret_cast<IMP>(&$LSDXPCServer$canOpenURL$connection$));
        }
    }
}
