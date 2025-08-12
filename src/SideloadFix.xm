#import "Header.h"

%hook CKEntitlements

- (id)initWithEntitlementsDict:(NSDictionary *)entitlements {
 
 NSMutableDictionary *mutableDict = [entitlements mutableCopy];
 
 [mutableDict removeObjectForKey:@"com.apple.developer.icloud-container-environment"];
 [mutableDict removeObjectForKey:@"com.apple.developer.icloud-services"];
 
 return %orig([mutableDict copy]);
} 

%end

%hook CKContainer
- (id)_setupWithContainerID:(id)a options:(id)b { return nil; }
- (id)_initWithContainerIdentifier:(id)a { return nil; }
%end

%hook NSFileManager
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
	if (NSURL *ourAppGroupURL = getAppGroupPathIfExists()) {
		NSURL *fakeAppGroupURL = [ourAppGroupURL URLByAppendingPathComponent:groupIdentifier];		
		createDirectoryIfNotExists(fakeAppGroupURL.path);
		return fakeAppGroupURL;
	}  
	
	// fallback to a fake App Group path in Documents/App Group
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *fakePath = [[paths lastObject] stringByAppendingPathComponent:groupIdentifier];
	createDirectoryIfNotExists(fakePath);
	return [NSURL fileURLWithPath:fakePath];
}
%end

%hook NSUserDefaults
- (id)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container {
	NSLog(@"[zx] hooking NSUserDefaults init...");

	NSURL *appGroupURL = getAppGroupPathIfExists();
	if (!appGroupURL) {
		NSLog(@"[zx] no valid app group available, defaulting to original container");
		return %orig(suiteName, container);
	}
	NSLog(@"[zx] app group URL: %@", appGroupURL);

	if (![suiteName hasPrefix:@"group"]) {
		NSLog(@"[zx] suite name '%@' does not start with 'group' ,, defaulting to original container", suiteName);
		return %orig(suiteName, container);
	}

	if (NSURL *customContainerURL = [appGroupURL URLByAppendingPathComponent:suiteName]) {
		NSLog(@"[zx] using custom container URL: %@", customContainerURL);
		return %orig(suiteName, customContainerURL);
	}

	NSLog(@"[zx] failed to construct valid URL for suite '%@' in app group container", suiteName);
	return %orig(suiteName, container);
}
%end
