/*
    Copyright (c) 2017-2020, Sveinbjorn Thordarson <sveinbjorn@sveinbjorn.org>
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

    1. Redistributions of source code must retain the above copyright notice, this
    list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright notice, this
    list of conditions and the following disclaimer in the documentation and/or other
    materials provided with the distribution.

    3. Neither the name of the copyright holder nor the names of its contributors may
    be used to endorse or promote products derived from this software without specific
    prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
    ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
    IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
    NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

#import <Foundation/Foundation.h>

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <err.h>
#include <string.h>
#include <unistd.h>
#include <sysexits.h>
#include <getopt.h>
#include <sys/attr.h>
#include <sys/param.h>
#include <sys/attr.h>
#include <sys/vnode.h>
#include <sys/fsgetpath.h>
#include <sys/mount.h>


struct packed_name_attr {
    u_int32_t               size;           // Of the remaining fields
    struct attrreference    ref;            // Offset/length of name itself
    char                    name[PATH_MAX];
};

struct packed_attr_ref {
    u_int32_t               size;           // Of the remaining fields
    struct attrreference    ref;            // Offset/length of attr itself
};

struct packed_result {
    u_int32_t           size;               // Including size field itself
    struct fsid         fs_id;
    struct fsobj_id     obj_id;
};
typedef struct packed_result packed_result;
typedef struct packed_result *packed_result_p;


#define MAX_MATCHES         20
#define MAX_EBUSY_RETRIES   5
#define DEFAULT_VOLUME      @"/"


// Prototypes
static void do_searchfs_search(const char *volpath, const char *match_string);
static BOOL filter_result(const char *path, const char *match_string);
static NSString *dev_to_mount_path(NSString *devPath);
static BOOL is_mount_path(NSString *path);
static BOOL vol_supports_searchfs(NSString *path);
static void list_volumes(void);
static void print_usage(void);
static void print_version(void);


static const float program_version = 0.4f;

static const char optstring[] = "v:dfespixnm:loh";

static struct option long_options[] = {
    {"volume",                  required_argument,      0,  'v'},
    {"dirs-only",               no_argument,            0,  'd'},
    {"files-only",              no_argument,            0,  'f'},
    {"exact-match",             no_argument,            0,  'e'},
    {"case-sensitive",          no_argument,            0,  's'},
    {"skip-packages",           no_argument,            0,  'p'},
    {"skip-invisibles",         no_argument,            0,  'i'},
    {"skip-inappropriate",      no_argument,            0,  'x'},
    {"negate-params",           no_argument,            0,  'n'},
    {"limit",                   required_argument,      0,  'm'},
    {"list",                    no_argument,            0,  'l'},
    {"version",                 no_argument,            0,  'o'},
    {"help",                    no_argument,            0,  'h'},
    {0,                         0,                      0,    0}
};

static BOOL dirsOnly = NO;
static BOOL filesOnly = NO;
static BOOL exactMatchOnly = NO;
static BOOL caseSensitive = NO;
static BOOL skipPackages = NO;
static BOOL skipInvisibles = NO;
static BOOL skipInappropriate = NO;
static BOOL negateParams = NO;
static NSUInteger limit = 0;
static BOOL startMatchOnly = NO;
static BOOL endMatchOnly = NO;


#pragma mark -

int main(int argc, const char *argv[]) {
    NSString *volumePath = DEFAULT_VOLUME;
    
    // Line-buffered output
    setvbuf(stdout, NULL, _IOLBF, BUFSIZ);
    
    // Parse options
    int optch;
    int long_index = 0;
    while ((optch = getopt_long(argc, (char *const *)argv, optstring, long_options, &long_index)) != -1) {
        switch (optch) {
            
            case 'l':
                list_volumes();
                exit(EX_OK);
                break;
            
            case 'v':
                volumePath = dev_to_mount_path([@(optarg) stringByResolvingSymlinksInPath]);
                break;
            
            case 'd':
                dirsOnly = YES;
                break;
            
            case 'f':
                filesOnly = YES;
                break;
            
            case 'e':
                exactMatchOnly = YES;
                break;
            
            case 's':
                caseSensitive = YES;
                break;
            
            case 'p':
                skipPackages = YES;
                break;
            
            case 'i':
                skipInvisibles = YES;
                break;
            
            case 'x':
                skipInappropriate = YES;
                break;
            
            case 'n':
                negateParams = YES;
                break;
            
            case 'm':
                limit = [@(optarg) integerValue];
                break;
            
            case 'o':
                print_version();
                exit(EX_OK);
                break;
            
            case 'h':
            default:
            {
                print_usage();
                exit(EX_OK);
            }
                break;
        }
    }
    
    if (dirsOnly && filesOnly) {
        fprintf(stderr, "-d and -f flags are mutually exclusive.\n");
        print_usage();
        exit(EX_USAGE);
    }

    // Verify that path is the mount path for a file system
    if (![volumePath isEqualToString:DEFAULT_VOLUME] && !is_mount_path(volumePath)) {
        fprintf(stderr, "Not a volume mount point: %s\n", [volumePath cStringUsingEncoding:NSUTF8StringEncoding]);
        print_usage();
        exit(EX_USAGE);
    }

    // Verify that volume supports catalog search
    if (!vol_supports_searchfs(volumePath)) {
        fprintf(stderr, "Voume does not support catalog search: %s\n", [volumePath cStringUsingEncoding:NSUTF8StringEncoding]);
        exit(EX_UNAVAILABLE);
    }
    
    if (optind >= argc) {
        print_usage();
        exit(EX_USAGE);
    }
    
    NSString *searchStr = @(argv[optind]);
    
    // Empty search string will match 0 results
//    if ([searchStr length] == 0 || [searchStr length] > PATH_MAX) {
//        fprintf(stderr, "Error: Invalid search string.\n");
//        exit(EX_USAGE);
//    }
    
    // Parse ^ and $ modifiers
    if ([searchStr hasPrefix:@"^"]) {
        startMatchOnly = YES;
        searchStr = [searchStr substringWithRange:NSMakeRange(1, [searchStr length] - 1)];
    }
    if ([searchStr hasSuffix:@"$"]) {
        endMatchOnly = YES;
        searchStr = [searchStr substringWithRange:NSMakeRange(0, [searchStr length] - 1)];
    }
    if (startMatchOnly && endMatchOnly) {
        exactMatchOnly = YES;
    }
    
    // Do search
    do_searchfs_search([volumePath cStringUsingEncoding:NSUTF8StringEncoding],
                       [searchStr cStringUsingEncoding:NSUTF8StringEncoding]);
 
    return EX_OK;
}

#pragma mark - search

static void do_searchfs_search(const char *volpath, const char *match_string) {
    // See "man 2 searchfs" for further details
    int                     err = 0;
    int                     items_found = 0;
    int                     ebusy_count = 0;
    unsigned long           matches;
    unsigned int            search_options;
    struct fssearchblock    search_blk;
    struct attrlist         return_list;
    struct searchstate      search_state;
    struct packed_name_attr info1;
    struct packed_attr_ref  info2;
    packed_result           result_buffer[MAX_MATCHES];
    
catalog_changed:
    items_found = 0; // Set this here in case we're completely restarting
    search_blk.searchattrs.bitmapcount = ATTR_BIT_MAP_COUNT;
    search_blk.searchattrs.reserved = 0;
    search_blk.searchattrs.commonattr = ATTR_CMN_NAME;
    search_blk.searchattrs.volattr = 0;
    search_blk.searchattrs.dirattr = 0;
    search_blk.searchattrs.fileattr = 0;
    search_blk.searchattrs.forkattr = 0;
    
    // Set up the attributes we want for all returned matches.
    search_blk.returnattrs = &return_list;
    return_list.bitmapcount = ATTR_BIT_MAP_COUNT;
    return_list.reserved = 0;
    return_list.commonattr = ATTR_CMN_FSID | ATTR_CMN_OBJID;
    return_list.volattr = 0;
    return_list.dirattr = 0;
    return_list.fileattr = 0;
    return_list.forkattr = 0;

    // Allocate a buffer for returned matches
    search_blk.returnbuffer = result_buffer;
    search_blk.returnbuffersize = sizeof(result_buffer);
    
    // Pack the searchparams1 into a buffer
    // NOTE: A name appears only in searchparams1
    strcpy(info1.name, match_string);
    info1.ref.attr_dataoffset = sizeof(struct attrreference);
    info1.ref.attr_length = (u_int32_t)strlen(info1.name) + 1;
    info1.size = sizeof(struct attrreference) + info1.ref.attr_length;
    search_blk.searchparams1 = &info1;
    search_blk.sizeofsearchparams1 = info1.size + sizeof(u_int32_t);
    
    // Pack the searchparams2 into a buffer
    info2.size = sizeof(struct attrreference);
    info2.ref.attr_dataoffset = sizeof(struct attrreference);
    info2.ref.attr_length = 0;
    search_blk.searchparams2 = &info2;
    search_blk.sizeofsearchparams2 = sizeof(info2);
    
    // Maximum number of matches we want
    search_blk.maxmatches = MAX_MATCHES;
    
    // Maximum time to search, per call
    search_blk.timelimit.tv_sec = 1;
    search_blk.timelimit.tv_usec = 0;
    
    // Configure search options
    search_options = SRCHFS_START;
    
    if (!dirsOnly) {
        search_options |= SRCHFS_MATCHFILES;
    }
    
    if (!filesOnly) {
        search_options |= SRCHFS_MATCHDIRS;
    }
    
    if (!exactMatchOnly) {
        search_options |= SRCHFS_MATCHPARTIALNAMES;
    }
    
    if (skipPackages) {
        search_options |= SRCHFS_SKIPPACKAGES;
    }
    
    if (skipInvisibles) {
        search_options |= SRCHFS_SKIPINVISIBLE;
    }
    
    if (skipInappropriate) {
        search_options |= SRCHFS_SKIPINAPPROPRIATE;
    }
    
    if (negateParams) {
        search_options |= SRCHFS_NEGATEPARAMS;
    }
    
    unsigned int match_cnt = 0;

    // Start searching
    do {
        err = searchfs(volpath, &search_blk, &matches, 0, search_options, &search_state);
        if (err == -1) {
            err = errno;
        }
        
        if ((err == 0 || err == EAGAIN) && matches > 0) {
            
            // Unpack the results
            char *ptr = (char *)&result_buffer[0];
            char *end_ptr = (ptr + sizeof(result_buffer));
            
            for (int i = 0; i < matches; ++i) {
                packed_result_p result_p = (packed_result_p)ptr;
                items_found++;
                
                // Call private SPI fsgetpath to get path string for file system object ID
                char path_buf[PATH_MAX];
                ssize_t size = fsgetpath((char *)&path_buf,
                                         sizeof(path_buf),
                                         &result_p->fs_id,
                                         (uint64_t)result_p->obj_id.fid_objno |
                                         ((uint64_t)result_p->obj_id.fid_generation << 32));
                if (size > -1) {
                    if (strlen(match_string) > 0 && !filter_result(path_buf, match_string)) {
                        fprintf(stdout, "%s\n", path_buf);
                        match_cnt++;
                        if (limit && match_cnt >= limit) {
                            return;
                        }
                    }
                } else {
                    // Getting path failed. This may be because the file system object
                    // was deleted in the interval between being found and path lookup.
                    // Fail silently.
//                    fprintf(stderr, "Unable to get path for object ID: %d\n", result_p->obj_id.fid_objno);
                }
                
                ptr = (ptr + result_p->size);
                if (ptr > end_ptr) {
                    break;
                }
            }
            
        }
        
        // EBUSY indicates catalog change; retry a few times.
        if ((err == EBUSY) && (ebusy_count++ < MAX_EBUSY_RETRIES)) {
            //fprintf(stderr, "EBUSY, trying again");
            goto catalog_changed;
        }
        
        if (err != 0 && err != EAGAIN) {
            fprintf(stderr, "searchfs() function failed with error %d - \"%s\"\n", err, strerror(err));
        }
        
        search_options &= ~SRCHFS_START;

    } while (err == EAGAIN);
}

#pragma mark - post-processing

BOOL filter_result(const char *path, const char *match_string) {
    if (!caseSensitive && !startMatchOnly && !endMatchOnly) {
        return NO;
    }
    
    NSString *pathStr = @(path);
    NSString *matchStr = @(match_string);
    
    if (caseSensitive) {
        NSString *escMatch = [NSRegularExpression escapedTemplateForString:matchStr];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:escMatch
                                                                               options:0
                                                                                 error:nil];
        NSTextCheckingResult *res = [regex firstMatchInString:pathStr
                                                      options:0
                                                        range:NSMakeRange(0, [pathStr length])];
        if (res == nil) {
            return YES;
        }
    }
    
    if (!exactMatchOnly) {
        if (startMatchOnly) {
            if (![[pathStr lastPathComponent] hasPrefix:matchStr]) {
                return YES;
            }
        }
        if (endMatchOnly) {
            if (![[pathStr lastPathComponent] hasSuffix:matchStr]) {
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark - util

static NSString *dev_to_mount_path(NSString *devPath) {
    // Check if string is a device path. If so, look up
    // the mount point for the device
    if ([[NSFileManager defaultManager] fileExistsAtPath:devPath] && ![devPath hasPrefix:@"/dev/"]) {
        return devPath;
    }
    
    if (![devPath hasPrefix:@"/"]) {
        // Could be a device name
        devPath = [NSString stringWithFormat:@"/dev/%@", devPath];
    }
    
    // Make sure it exists
    if (![[NSFileManager defaultManager] fileExistsAtPath:devPath]) {
        fprintf(stderr, "No such device: %s\n",
                [devPath cStringUsingEncoding:NSUTF8StringEncoding]);
        exit(EX_UNAVAILABLE);
    }
    
    // Look up mount point for device
    int fs_count = getfsstat(NULL, 0, MNT_NOWAIT);
    if (fs_count == -1) {
        fprintf(stderr, "Error: %d\n", errno);
        return nil;
    }
    
    struct statfs buf[256];
    getfsstat(buf, fs_count * sizeof(buf[0]), MNT_NOWAIT);
    
    for (int i = 0; i < fs_count; ++i) {
        if ([@(buf[i].f_mntfromname) isEqualToString:devPath]) {
            return @(buf[i].f_mntonname);
        }
    }
    return nil;
}

static BOOL is_mount_path(NSString *path) {
    return YES;
//    NSArray *mountPaths = [[NSFileManager defaultManager] mountedVolumeURLsIncludingResourceValuesForKeys:nil options:0];
//    for (NSURL *mountPathURL in mountPaths) {
//        if ([path isEqualToString:[mountPathURL path]]) {
//            return YES;
//        }
//    }
//    
//    return NO;
}

static BOOL vol_supports_searchfs(NSString *path) {
    
    struct vol_attr_buf {
        u_int32_t               size;
        vol_capabilities_attr_t vol_capabilities;
    } __attribute__((aligned(4), packed));
    
    const char *p = [path cStringUsingEncoding:NSUTF8StringEncoding];
    
    struct attrlist attrList;
    memset(&attrList, 0, sizeof(attrList));
    attrList.bitmapcount = ATTR_BIT_MAP_COUNT;
    attrList.volattr = (ATTR_VOL_INFO | ATTR_VOL_CAPABILITIES);
    
    struct vol_attr_buf attrBuf;
    memset(&attrBuf, 0, sizeof(attrBuf));
    
    int err = getattrlist(p, &attrList, &attrBuf, sizeof(attrBuf), 0);
    if (err != 0) {
        err = errno;
        fprintf(stderr, "Error %d getting attrs for volume %s\n", err, p);
        return NO;
    }
    
    assert(attrBuf.size == sizeof(attrBuf));
        
    if ((attrBuf.vol_capabilities.valid[VOL_CAPABILITIES_INTERFACES] & VOL_CAP_INT_SEARCHFS) == VOL_CAP_INT_SEARCHFS) {
        if ((attrBuf.vol_capabilities.capabilities[VOL_CAPABILITIES_INTERFACES] & VOL_CAP_INT_SEARCHFS) == VOL_CAP_INT_SEARCHFS) {
            return YES;
        }
    }
    
    return NO;
}

static void list_volumes(void) {
    
    int fs_count = getfsstat(NULL, 0, MNT_NOWAIT);
    if (fs_count == -1) {
        fprintf(stderr, "Error: %d\n", errno);
        return;
    }
    
    struct statfs buf[256];
    getfsstat(buf, fs_count * sizeof(buf[0]), MNT_NOWAIT);
    
    for (int i = 0; i < fs_count; ++i) {
        if (!vol_supports_searchfs(@(buf[i].f_mntonname))) {
            continue;
        }
        
        printf("%s (%-4s): %s\n",
               buf[i].f_mntfromname,
               buf[i].f_fstypename,
               buf[i].f_mntonname);
    }
}

#pragma mark -

static void print_usage(void) {
    fprintf(stderr, "usage: searchfs [-ldfespixnmoh] [-v mount_point] search_term\n");
}

static void print_version(void) {
    printf("searchfs version %.2f\n", program_version);
}
