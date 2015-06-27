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

#include <objc/runtime.h>
#include <Foundation/Foundation.h>

@interface MIFileManager
+ (MIFileManager *) defaultManager;
- (NSURL *) destinationOfSymbolicLinkAtURL:(NSURL *)url error:(NSError *)error;
@end

static Class $MIFileManager;

static NSArray *(*_MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$)(MIFileManager *self, SEL _cmd, NSURL *url, BOOL ignoring, NSError *error);

static NSArray *$MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$(MIFileManager *self, SEL _cmd, NSURL *url, BOOL ignoring, NSError *error) {
    MIFileManager *manager(reinterpret_cast<MIFileManager *>([$MIFileManager defaultManager]));
    NSURL *destiny([manager destinationOfSymbolicLinkAtURL:url error:NULL]);
    if (destiny == nil)
        return _MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$(self, _cmd, url, YES, error);

    NSArray *prefix([url pathComponents]);
    size_t skip([[destiny pathComponents] count]);
    NSMutableArray *items([NSMutableArray array]);
    for (NSURL *item in _MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$(self, _cmd, destiny, YES, error)) {
        NSArray *components([item pathComponents]);
        [items addObject:[NSURL fileURLWithPathComponents:[prefix arrayByAddingObjectsFromArray:[components subarrayWithRange:NSMakeRange(skip, [components count] - skip)]]]];
    }

    return items;
}

__attribute__((__constructor__))
static void initialize() {
    $MIFileManager = objc_getClass("MIFileManager");
    SEL sel(@selector(urlsForItemsInDirectoryAtURL:ignoringSymlinks:error:));
    Method method(class_getInstanceMethod($MIFileManager, sel));
    _MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$ = reinterpret_cast<NSArray *(*)(MIFileManager *, SEL, NSURL *, BOOL, NSError *)>(method_getImplementation(method));
    method_setImplementation(method, reinterpret_cast<IMP>(&$MIFileManager$urlsForItemsInDirectoryAtURL$ignoringSymlinks$error$));
}
