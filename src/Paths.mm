#import <objc/runtime.h>

#import "Header.h"

BOOL createDirectoryIfNotExists(NSString *path) {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path]) {
		NSLog(@"[zx] directory already exists: %@", path);
		return YES;
	}

	NSError *error = nil;
	[fileManager createDirectoryAtPath:path
		   withIntermediateDirectories:YES
							attributes:nil
								 error:&error];

	if (error) {
		NSLog(@"[zx] failed to create directory at path (%@): %@", path, error);
		return NO;
	}

	NSLog(@"[zx] created directory at path: %@", path);
	return YES;
}

NSURL *getAppGroupPathIfExists() {
	static NSURL *cachedAppGroupPath = nil;
	static dispatch_once_t onceToken;
	 
	dispatch_once(&onceToken, ^{
		NSLog(@"[zx] fetching app group path...");
		
		LSBundleProxy *bundleProxy = [objc_getClass("LSBundleProxy") bundleProxyForCurrentProcess];
		if (!bundleProxy) {
			NSLog(@"[zx] failed to retrieve LSBundleProxy for the current process");
			return;
		}
		
		NSDictionary *entitlements = bundleProxy.entitlements;
		if (!entitlements || ![entitlements isKindOfClass:[NSDictionary class]]) {
			NSLog(@"[zx] failed to retrieve entitlements");
			return;
		}
		
		NSArray *appGroups = entitlements[@"com.apple.security.application-groups"];
		if (!appGroups) {
			NSLog(@"[zx] no app groups found in entitlements");
			return;
		}
		
		if (appGroups.count == 0) {
			NSLog(@"[zx] app group entitlement exists, but no app groups are configured");
			return;
		}
		
		NSString *appGroupName = [appGroups firstObject];
		NSLog(@"[zx] app group name: %@", appGroupName);
		
		NSDictionary *appGroupsPaths = bundleProxy.groupContainerURLs;
		if (!appGroupsPaths || ![appGroupsPaths isKindOfClass:[NSDictionary class]]) {
			NSLog(@"[zx] failed to retrieve group container URLs");
			return;
		}
		
		NSURL *ourAppGroupURL = appGroupsPaths[appGroupName];
		if (ourAppGroupURL) {
			cachedAppGroupPath = ourAppGroupURL;
			NSLog(@"[zx] app group path: %@", cachedAppGroupPath.path);
		} else {
			NSLog(@"[zx] no path found for app group name: %@", appGroupName);
		}
	});
	
	return cachedAppGroupPath;
}