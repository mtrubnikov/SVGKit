//
//  SVGGroupElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGGroupElement.h"

#import "SVGDocument.h"

#import "SVGElement+Private.h"
#import "CALayerWithChildHitTest.h"

@implementation SVGGroupElement

@synthesize opacity = _opacity;
@synthesize attributes = _attributes;

//didn't want to make a new utils class to store this function and it's needed by children of this class so it was the most convenient, would be better as a categorical function on NSDictinoary though

-(NSDictionary *)fillBlanksInDictionary:(NSDictionary *)highPriority
{
    if( self.attributes == nil )
        return highPriority;
    return [self dictionaryByMergingDictionary:self.attributes overridenByDictionary:highPriority];
}

-(NSDictionary *)dictionaryByMergingDictionary:(NSDictionary *)lowPriority overridenByDictionary:(NSDictionary *)highPriority
{
    NSArray *allKeys = [[lowPriority allKeys] arrayByAddingObjectsFromArray:[highPriority allKeys]];
    
    NSArray *allValues = [[lowPriority allValues] arrayByAddingObjectsFromArray:[highPriority allValues]];
    
    return [NSDictionary dictionaryWithObjects:allValues forKeys:allKeys];
}


+ (void)trim
{
    
}

- (void)dealloc {
    [_attributes release];
    [super dealloc];
}

- (void)loadDefaults {
	_opacity = 1.0f;
}

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
	
	id value = nil;
	
	if ((value = [attributes objectForKey:@"opacity"])) { //opacity of all elements in this group
		_opacity = [value floatValue];
	}
    
    //we can't propagate opacity down unfortunately, so we need to build a set of all the properties except a few (opacity is applied differently to groups than simply inheriting it to it's children, <g opacity occurs AFTER blending all of its children
    
    BOOL attributesFound = NO;
    NSMutableDictionary *buildDictionary = [NSMutableDictionary new];
    for( NSString *key in attributes )
    {
        if( ![key isEqualToString:@"opacity"] )
        {
            attributesFound = YES;
            [buildDictionary setObject:[attributes objectForKey:key] forKey:key];
        }
    }
    
    if( attributesFound )
    {
        _attributes = [[NSDictionary alloc] initWithDictionary:buildDictionary];
        //these properties are inherited by children of this group
    }
    [buildDictionary release];
}

- (CALayer *)autoreleasedLayer {
	
	CALayer* _layer = [CALayerWithChildHitTest layer];
		
		_layer.name = self.identifier;
		[_layer setValue:self.identifier forKey:kSVGElementIdentifier];
		_layer.opacity = _opacity;
    
#if RASTERIZE_SHAPES > 0
		if ([_layer respondsToSelector:@selector(setShouldRasterize:)]) {
			[_layer performSelector:@selector(setShouldRasterize:)
						withObject:[NSNumber numberWithBool:YES]];
		}
#endif
	
	return _layer;
}

- (void)layoutLayer:(CALayer *)layer {
	NSArray *sublayers = [layer sublayers];
	CGRect frameRect = CGRectZero;
    CGRect mainRect = CGRectZero;
    CGRect boundsRect = CGRectZero;
	
	for (NSUInteger n = 0; n < [sublayers count]; n++) {
		CALayer *currentLayer = [sublayers objectAtIndex:n];
		
		if (n == 0) {
			frameRect = currentLayer.frame;
		}
		else {
			frameRect = CGRectUnion(frameRect, currentLayer.frame);
		}
        mainRect = CGRectUnion(mainRect, currentLayer.frame);
	}
	
	frameRect = CGRectIntegral(frameRect); // round values to integers
	mainRect = CGRectIntegral(mainRect); // round values to integers
    
    boundsRect = CGRectOffset(frameRect, -frameRect.origin.x, -frameRect.origin.y);
	
    for (CALayer *currentLayer in sublayers) {
//		CGRect frame = currentLayer.frame;
//		frame.origin.x -= frameRect.origin.x;
//		frame.origin.y -= frameRect.origin.y;
//		
//		currentLayer.frame = CGRectIntegral(frame);
        [currentLayer setAffineTransform:CGAffineTransformConcat(currentLayer.affineTransform, CGAffineTransformMakeTranslation(-frameRect.origin.x, -frameRect.origin.y))];
	}
    
	layer.frame = boundsRect;
    
    //outline
    
#if OUTLINE_SHAPES
    
    layer.borderColor = [UIColor redColor].CGColor;
    layer.borderWidth = 1.0f;
    
    NSString* textToDraw = [NSString stringWithFormat:@"%@ (%@): {%.1f, %.1f} {%.1f, %.1f}", self.identifier, [self class], layer.frame.origin.x, layer.frame.origin.y, layer.frame.size.width, layer.frame.size.height];
    
    UIFont* fontToDraw = [UIFont fontWithName:@"Helvetica"
                                         size:10.0f];
    CGSize sizeOfTextRect = [textToDraw sizeWithFont:fontToDraw];
    
    CATextLayer *debugText = [[[CATextLayer alloc] init] autorelease];
    [debugText setFont:@"Helvetica"];
    [debugText setFontSize:10.0f];
    [debugText setFrame:CGRectMake(0, 0, sizeOfTextRect.width, sizeOfTextRect.height)];
    [debugText setString:textToDraw];
    [debugText setAlignmentMode:kCAAlignmentLeft];
    [debugText setForegroundColor:[UIColor redColor].CGColor];
    [debugText setContentsScale:[[UIScreen mainScreen] scale]];
    [debugText setShouldRasterize:NO];
    [layer addSublayer:debugText];
    
#endif
    
    //applying transform relative to centerpoint
    CGAffineTransform tr1 = layer.affineTransform;
    tr1 = CGAffineTransformConcat(tr1, CGAffineTransformMakeTranslation(frameRect.size.width/2, frameRect.size.height/2));
    CGAffineTransform tr2 = CGAffineTransformConcat(tr1, self.transformRelative);
    tr2 = CGAffineTransformConcat(tr2, CGAffineTransformInvert(tr1));
    tr1 = CGAffineTransformConcat(CGAffineTransformMakeTranslation(frameRect.origin.x, frameRect.origin.y), tr2);
    [layer setAffineTransform:tr1];
}

@end
