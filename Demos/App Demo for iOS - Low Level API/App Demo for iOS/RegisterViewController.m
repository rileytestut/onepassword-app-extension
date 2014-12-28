//
//  SignUpViewController.m
//  1Password Extension Demo
//
//  Created by Rad Azzouz on 2014-07-17.
//  Copyright (c) 2014 AgileBits. All rights reserved.
//

#import "RegisterViewController.h"
#import "RSTOnePasswordExtension.h"
#import "LoginInformation.h"

@interface RegisterViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *onepasswordSignupButton;

@property (weak, nonatomic) IBOutlet UITextField *firstnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *lastnameTextField;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation RegisterViewController

- (void)viewDidLoad {
	[self.view setBackgroundColor:[[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"register-background.png"]]];
	[self.onepasswordSignupButton setHidden:![[RSTOnePasswordExtension sharedExtension] isAppExtensionAvailable]];
}

- (UIStatusBarStyle)preferredStatusBarStyle{
	return UIStatusBarStyleDefault;
}

- (IBAction)saveLoginTo1Password:(id)sender {
	NSDictionary *newLoginDetails = @{
		AppExtensionTitleKey: @"ACME",
		AppExtensionUsernameKey: self.usernameTextField.text ? : @"",
		AppExtensionPasswordKey: self.passwordTextField.text ? : @"",
		AppExtensionNotesKey: @"Saved with the ACME app",
		AppExtensionSectionTitleKey: @"ACME Browser",
		AppExtensionFieldsKey: @{
			  @"firstname" : self.firstnameTextField.text ? : @"",
			  @"lastname" : self.lastnameTextField.text ? : @""
			  // Add as many string fields as you please.
		}
	};
	
	// Password generation options are optional, but are very handy in case you have strict rules about password lengths
	NSDictionary *passwordGenerationOptions = @{
		AppExtensionGeneratedPasswordMinLengthKey: @(6),
		AppExtensionGeneratedPasswordMaxLengthKey: @(50)
	};

	RSTOnePasswordExtension *onePasswordExtension = [RSTOnePasswordExtension sharedExtension];

	// Create the 1Password extension item.
	NSExtensionItem *extensionItem = [onePasswordExtension createExtensionItemToStoreLoginForURLString:@"https://www.acme.com" loginDetails:newLoginDetails passwordGenerationOptions:passwordGenerationOptions];

	NSArray *activityItems = @[ extensionItem ]; // Add as many activity items as you please

	// Setting up the activity view controller
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems  applicationActivities:nil];

	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		self.popoverPresentationController.barButtonItem = sender;
	}
	else if ([sender isKindOfClass:[UIView class]]) {
		self.popoverPresentationController.sourceView = [sender superview];
		self.popoverPresentationController.sourceRect = [sender frame];
	}

	activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError)
	{
		// Executed when the 1Password Extension is called
		if ([onePasswordExtension isOnePasswordExtensionActivityType:activityType]) {
			if (returnedItems.count > 0) {
				__weak typeof (self) miniMe = self;
				[onePasswordExtension processReturnedItems:returnedItems completion:^(NSDictionary *loginDict, NSError *error) {
					if (!loginDict) {
						if (error.code != AppExtensionErrorCodeCancelledByUser) {
							NSLog(@"Failed to use 1Password App Extension to save a new Login: %@", error);
						}
						return;
					}

					__strong typeof(self) strongMe = miniMe;

					strongMe.usernameTextField.text = loginDict[AppExtensionUsernameKey] ? : @"";
					strongMe.passwordTextField.text = loginDict[AppExtensionPasswordKey] ? : @"";
					strongMe.firstnameTextField.text = loginDict[AppExtensionReturnedFieldsKey][@"firstname"] ? : @"";
					strongMe.lastnameTextField.text = loginDict[AppExtensionReturnedFieldsKey][@"lastname"] ? : @"";
					// retrieve any additional fields that were passed in newLoginDetails dictionary

					[LoginInformation sharedLoginInformation].username = loginDict[AppExtensionUsernameKey];
				}];
			}
		}
		else {
			// Code for other activity types
		}
	};

	[self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (textField == self.usernameTextField) {
		[LoginInformation sharedLoginInformation].username = textField.text;
	}
}
@end
