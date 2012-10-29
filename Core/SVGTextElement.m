//
//  SVGTextElement.m
//  SVGPad
//
//  Created by Steven Fusco on 11/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVGTextElement.h"
#import "UIColor-Expanded.h"
#import "CATextLayerWithHitTest.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#define DEFAULT_FONT_FAMILY @"Helvetica"
#define DEFAULT_FILL [UIColor blackColor]

@implementation SVGTextElement

+ (BOOL)shouldStoreContent {
    return YES;
}

+ (void)trim
{
    //free statically allocated memory
}

@synthesize x = _x;
@synthesize y = _y;
@synthesize fontFamily = _fontFamily;
@synthesize fontSize = _fontSize;
@synthesize fill = _fill;

- (NSString *)fontFamily
{
    if(!_fontFamily || ![[UIFont familyNames] containsObject:_fontFamily]) {
        return DEFAULT_FONT_FAMILY;
    } else {
        return _fontFamily;
    }
}

- (UIColor *)fill
{
    if(!_fill) {
        return DEFAULT_FILL;
    } else {
        return _fill;
    }
}

- (void)dealloc {
    [_fontFamily release];
    [super dealloc];
}

- (void)parseAttributes:(NSDictionary *)attributes
{
    [super parseAttributes:attributes];
    
	id value = nil;
    
	if ((value = [attributes objectForKey:@"x"])) {
		_x = [value floatValue];
	}
    
	if ((value = [attributes objectForKey:@"y"])) {
		_y = [value floatValue];
	}
    
    if ((value = [attributes objectForKey:@"font-family"])) {
        self.fontFamily = value;
    }
    
    if ((value = [attributes objectForKey:@"font-size"])) {
        self.fontSize = [value floatValue];
    }
    
    if ((value = [attributes objectForKey:@"fill"])) {
        self.fill = [UIColor colorWithHexString:value];
    }
    
    if ((value = [attributes objectForKey:@"fill-opacity"])) {
        self.fill = [UIColor colorWithRed:self.fill.red green:self.fill.green blue:self.fill.blue alpha:[value floatValue]];
    }
    
    // TODO: class
    // TODO: style
    // TODO: externalResourcesRequired
    // TODO: transform
    // TODO: lengthAdjust
    // TODO: rotate
    // TODO: textLength
    // TODO: dx
    // TODO: dy
    // TODO: fill
    
//     fill = "#000000";                            +
//    "fill-opacity" = 1;                           +
//    "font-family" = Sans;                         +
//    "font-size" = "263.27566528px";               +
//    "font-stretch" = normal;                      -
//    "font-style" = normal;                        -
//    "font-variant" = normal;                      -
//    "font-weight" = normal;                       -
//    id = text2816;                                -
//    "line-height" = "125%";                       -
//    linespacing = "125%";                         -
//    space = preserve;                             -
//    stroke = none;                                -
//    "text-align" = start;                         -
//    "text-anchor" = start;                        -
//    transform = "scale(0.80449853,1.2430103)";    -
//    "writing-mode" = "lr-tb";                     -

}

- (CALayer *) autoreleasedLayer {
#if TARGET_OS_IPHONE
    NSString* textToDraw = self.stringValue;
    
    UIFont* fontToDraw = [UIFont fontWithName:self.fontFamily
                                         size:self.fontSize];
    CGSize sizeOfTextRect = [textToDraw sizeWithFont:fontToDraw];
    
    CATextLayerWithHitTest *label = [[[CATextLayerWithHitTest alloc] init] autorelease];
    [label setName:self.identifier];
    [label setFont:self.fontFamily];
    [label setFontSize:self.fontSize];
    //making the text to draw at the correct point (baseline beginning)
    //moved to transforms
    [label setFrame:CGRectMake(0, 0, sizeOfTextRect.width, sizeOfTextRect.height)];
    [label setString:textToDraw];
    [label setAlignmentMode:kCAAlignmentLeft];
    [label setForegroundColor:[self.fill CGColor]];
//    [label setContentsScale:[[UIScreen mainScreen] scale]];
//    [label setRasterizationScale:[[UIScreen mainScreen] scale]];
//    [label setShouldRasterize:NO];
    
    //rotating around basepoint
    CGAffineTransform tr1 = CGAffineTransformIdentity;
    CGAffineTransform tr2 = CGAffineTransformConcat(tr1, self.transformRelative);
    tr2 = CGAffineTransformConcat(tr2, CGAffineTransformInvert(tr1));
    
    tr2 = CGAffineTransformConcat(CGAffineTransformMakeTranslation(_x, _y - fontToDraw.ascender), tr2);
    
    [label setAffineTransform:tr2];
    
#if OUTLINE_SHAPES
    
    label.borderColor = [UIColor blueColor].CGColor;
    label.borderWidth = 1.0f;
    
#endif
    
    return label;
#else
    return nil;
#endif
}

- (void)layoutLayer:(CALayer *)layer
{

}

@end
