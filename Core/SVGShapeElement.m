//
//  SVGShapeElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGShapeElement.h"

#import "CGPathAdditions.h"
#import "SVGDefsElement.h"
#import "SVGDocument.h"
#import "SVGElement+Private.h"
#import "SVGPattern.h"
#import "CAShapeLayerWithHitTest.h"

#define ADAM_IS_FIXING_THE_TRANSFORM_AND_VIEW_BOX_CODE 0

@implementation SVGShapeElement

#define IDENTIFIER_LEN 256

@synthesize x = _x;
@synthesize y = _y;

@synthesize opacity = _opacity;

@synthesize fillType = _fillType;
@synthesize fillColor = _fillColor;
@synthesize fillPattern = _fillPattern;

@synthesize strokeWidth = _strokeWidth;
@synthesize strokeColor = _strokeColor;

@synthesize path = _path;

@synthesize fillId = _fillId;
+(void)trim
{
    //free statically allocated memory that is not needed
}

- (void)finalize {
	CGPathRelease(_path);
	[super finalize];
}

-(void)setFillColor:(SVGColor)fillColor
{
    _fillColor = fillColor;
    _fillType = SVGFillTypeSolid;
    
    if( _fillCG != nil )
        CGColorRelease(_fillCG);
    _fillCG = CGColorRetain(CGColorWithSVGColor(fillColor));
}

- (void)dealloc {
	[self loadPath:NULL];
    [self setFillPattern:nil];
    [_fillId release];
    [_styleClass release];
    
    if( _fillCG != nil )
        CGColorRelease(_fillCG);
    
    if( _strokeCG != nil )
        CGColorRelease(_strokeCG);
    
	[super dealloc];
}

- (void)loadDefaults {
	_opacity = 1.0f;
	
	_fillColor = SVGColorMake(0, 0, 0, 255);
	_fillType = SVGFillTypeSolid;
}

- (void)parseAttributes:(NSDictionary *)attributes {
	[super parseAttributes:attributes];
	
    if( [self.parent isKindOfClass:[SVGGroupElement class]] )
        attributes = [(SVGGroupElement *)self.parent fillBlanksInDictionary:attributes];
    
	id value = nil;
    
    if ((value = [attributes objectForKey:@"x"])) {
		_x = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"y"])) {
		_y = [value floatValue];
	}
    
    if( (value = [attributes objectForKey:@"class"] ) )
    {
        _styleClass = [value copy];
    }
	
	if ((value = [attributes objectForKey:@"opacity"])) {
		_opacity = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"fill"])) {
		const char *cvalue = [value UTF8String];
		
		if (!strncmp(cvalue, "none", 4)) {
			_fillType = SVGFillTypeNone;
		}
		else if (!strncmp(cvalue, "url", 3)) {
			_fillType = SVGFillTypeURL;
            NSRange idKeyRange = NSMakeRange(5, [value length] - 6);
            _fillId = [[value substringWithRange:idKeyRange] retain];
		}
		else {
			_fillColor = SVGColorFromString([value UTF8String]);
			_fillType = SVGFillTypeSolid;
		}
	}
	
	if ((value = [attributes objectForKey:@"stroke-width"])) {
		_strokeWidth = [value floatValue];
	}
	
	if ((value = [attributes objectForKey:@"stroke"])) {
		const char *cvalue = [value UTF8String];
		
		if (!strncmp(cvalue, "none", 4)) {
			_strokeWidth = 0.0f;
		}
		else {
			_strokeColor = SVGColorFromString(cvalue);
			
			if (!_strokeWidth)
				_strokeWidth = 1.0f;
		}
	}
	
	if ((value = [attributes objectForKey:@"stroke-opacity"])) {
		_strokeColor.a = (uint8_t) ([value floatValue] * 0xFF);
	}
	
	if ((value = [attributes objectForKey:@"fill-opacity"])) {
		_fillColor.a = (uint8_t) ([value floatValue] * 0xFF);
	}
    
    if(_strokeWidth)
        _strokeCG = CGColorRetain(CGColorWithSVGColor(_strokeColor));
    
    if(_fillType == SVGFillTypeSolid)
        _fillCG = CGColorRetain(CGColorWithSVGColor(_fillColor));
    
}

- (void)loadPath:(CGPathRef)aPath {
	if (_path) {
		CGPathRelease(_path);
		_path = NULL;
	}
	
	if (aPath) {
        _layerRect = CGRectIntegral(CGPathGetPathBoundingBox(aPath));
//        CGPoint origin = _layerRect.origin;
//        aPath = CGPathCreateByOffsettingPath(aPath, origin.x, origin.y);
//		_path = aPath;
        
        _path = CGPathCreateCopy(aPath);
	}
}

- (CALayer *) autoreleasedLayer {
	CAShapeLayer* _shapeLayer = [CAShapeLayerWithHitTest layer];
	_shapeLayer.name = self.identifier;
		[_shapeLayer setValue:self.identifier forKey:kSVGElementIdentifier];
	_shapeLayer.opacity = _opacity;
    
    
//unused
//#if EXPERIMENTAL_SUPPORT_FOR_SVG_TRANSFORM_ATTRIBUTES
//	CGAffineTransform svgEffectiveTransform = [self transformAbsolute];
//#endif
	
    
    //stich: i found this to be unnecessar in practice but maybe I was wrong, this operation is happening in loadPath now (less total paths if document is reused)
//    CGRect rect = CGRectIntegral(CGPathGetPathBoundingBox(_path));
	
//    CGPoint origin = rect.origin;
    
//    NSValue *lastOrigin = [_shapeLayer valueForKey:@"debugSomeStuff"];
    
    //seems like the origin doesn't change, move this to load path
//    NSLog(@"Origin is %@", NSStringFromCGPoint(origin));
//    if( lastOrigin!= nil && !CGPointEqualToPoint([lastOrigin CGPointValue], origin) )
//    {
//        NSLog(@"Oh no our origin changed :(");
//    }
//    else
//        [_shapeLayer setValue:[NSValue valueWithCGPoint:origin] forKey:@"debugSomeStuff"];
    
	CGPathRef path = CGPathCreateByOffsettingPath(_path, _layerRect.origin.x, _layerRect.origin.y);
	
	_shapeLayer.path = path;
	CGPathRelease(path);
	
	_shapeLayer.frame = _layerRect;
//    CGRectMake(0, 0, _layerRect.size.width, _layerRect.size.height);
    
//#warning Sorry adam, I had to disable this to make sure my stuff was working post-merge

    
//    stich: This is seriously mangling the lion so I have disabled to make sure the rest of the merge went OK
    //For now a good solution may be to create a CALayer explicitly for applying the transform?
    
#if ADAM_IS_FIXING_THE_TRANSFORM_AND_VIEW_BOX_CODE
    /*
	To fix this, and to test the code that follows, you need to:
	
	1. create a simple SVG file with a single square
	2. Set the viewport to be straingely shaped (e.g. a fat short rectangle)
	3. set the square to fill the exact bottom right of viewport
	
	...which will let you see easily if/when the viewbox is being correctly used to scale the contents
	*/
	/**
	 We've parsed this shape using the size values specified RAW inside the SVG.
	 
	 Before we attempt to *render* it, we need to convert those values into
	 screen-space.
	 
	 Most SVG docs have screenspace == unit space - but some docs have an explicit "viewBox"
	 attribute on the SVG document. As per the SVG spec, this defines an alternative
	 conversion from unit space to screenspace
	 */
    
#endif
//	CGAffineTransform transformFromSVGUnitsToScreenUnits;
//
//	#if ADAM_IS_FIXING_THE_TRANSFORM_AND_VIEW_BOX_CODE
//	if( CGRectIsNull( self.document.viewBoxFrame ) )
//#endif
//		transformFromSVGUnitsToScreenUnits = CGAffineTransformIdentity;
//	#if ADAM_IS_FIXING_THE_TRANSFORM_AND_VIEW_BOX_CODE
//	else
//		transformFromSVGUnitsToScreenUnits = CGAffineTransformMakeScale( self.document.width / self.document.viewBoxFrame.size.width,
//																		 self.document.height / self.document.viewBoxFrame.size.height );
//#endif
	
//	CGMutablePathRef pathToPlaceInLayer = CGPathCreateMutable();
//	CGPathAddPath( pathToPlaceInLayer, &transformFromSVGUnitsToScreenUnits, _path);
//	
//    CGRect rect = CGRectIntegral(CGPathGetPathBoundingBox( pathToPlaceInLayer ));
//    CGRect rect = CGRectIntegral(CGPathGetPathBoundingBox( _path ));
	
//что за хуйня?
//эта сцука сдвигает все элементы в -x, -y!
//	CGPathRef finalPath = CGPathCreateByOffsettingPath( pathToPlaceInLayer, rect.origin.x, rect.origin.y );
// 	CGPathRef finalPath = CGPathCreateByOffsettingPath( _path, rect.origin.x, rect.origin.y );

	/** Can't use this - iOS 5 only! path = CGPathCreateCopyByTransformingPath(path, transformFromSVGUnitsToScreenUnits ); */
	
//	_shapeLayer.path = _path;
//	CGPathRelease(finalPath);
//	CGPathRelease(pathToPlaceInLayer);

//#if EXPERIMENTAL_SUPPORT_FOR_SVG_TRANSFORM_ATTRIBUTES
//	/**
//	 ADAM: this is an INCOMPLETE implementation of SVG transform. The original code only deals with offsets (translate).
//	 We're actually correctly parsing + calculating SVG's arbitrary transforms - but it will require a lot more work at
//	 this point here to interpret those arbitrary transforms correctly.
//	 
//	 For now, we're just going to assume we're only doing translates.
//	 */
//	/**
//	 NB: this line, by changing the FRAME of the layer, has the side effect of also changing the CGPATH's position in absolute
//	 space!
//     
//     */
//	_shapeLayer.frame = CGRectApplyAffineTransform( rect, svgEffectiveTransform );
//#else
//	_shapeLayer.frame = rect;
//#endif
    
//    _shapeLayer.frame = rect;
    
    //rotating around basepoint
//    CGAffineTransform tr3 = CGAffineTransformConcat(CGAffineTransformMakeTranslation(rect.origin.x, rect.origin.y), self.transformAbsolute);
    
//    [_shapeLayer setAffineTransform:self.transformRelative];
    CGAffineTransform tr1 = self.transformRelative;
    tr1 = CGAffineTransformConcat(CGAffineTransformMakeTranslation(_x, _y), tr1);
    [_shapeLayer setAffineTransform:tr1];
	
	if (_strokeWidth) {
		_shapeLayer.lineWidth = _strokeWidth;
		_shapeLayer.strokeColor = _strokeCG;// CGColorWithSVGColor(_strokeColor);
	}
	
    CALayer *returnLayer = _shapeLayer;
    
    switch( _fillType )
    {
        case SVGFillTypeNone:
            _shapeLayer.fillColor = nil;
            break;
        case SVGFillTypeSolid:
            _shapeLayer.fillColor = _fillCG;
            break;
            
        case SVGFillTypeURL:
            returnLayer = [_document useFillId:_fillId forLayer:_shapeLayer]; //CAGradientLayer does not extend from CAShapeLayer, although this doens't actually work :/

            break;
    }
    
    if (nil != _fillPattern) {
        _shapeLayer.fillColor = [_fillPattern CGColor];
    }
    
    
#if OUTLINE_SHAPES
	
#if TARGET_OS_IPHONE
	_shapeLayer.borderColor = [UIColor greenColor].CGColor;
#endif
	
	_shapeLayer.borderWidth = 1.0f;
    
    NSString* textToDraw = [NSString stringWithFormat:@"%@ (%@): {%.1f, %.1f} {%.1f, %.1f}", self.identifier, [self class], _shapeLayer.frame.origin.x, _shapeLayer.frame.origin.y, _shapeLayer.frame.size.width, _shapeLayer.frame.size.height];
    
    UIFont* fontToDraw = [UIFont fontWithName:@"Helvetica"
                                         size:10.0f];
    CGSize sizeOfTextRect = [textToDraw sizeWithFont:fontToDraw];
    
    CATextLayer *debugText = [[[CATextLayer alloc] init] autorelease];
    [debugText setFont:@"Helvetica"];
    [debugText setFontSize:10.0f];
    [debugText setFrame:CGRectMake(0, 0, sizeOfTextRect.width, sizeOfTextRect.height)];
    [debugText setString:textToDraw];
    [debugText setAlignmentMode:kCAAlignmentLeft];
    [debugText setForegroundColor:[UIColor greenColor].CGColor];
    [debugText setContentsScale:[[UIScreen mainScreen] scale]];
    [debugText setShouldRasterize:NO];
    [_shapeLayer addSublayer:debugText];
    
#endif
	
    
#ifndef STATIC_COLORS 
    //if STATIC_COLORS is not set, we may want to track shapeLayers for style changes
    if( _styleClass != nil )
    {
        NSObject<SVGStyleCatcher> *docCatcher = [_document catcher];
        if( docCatcher != nil ) //this might need to happen after gradients are resolved to track the correct element, not sure yet
            [docCatcher styleCatchLayer:_shapeLayer forClass:_styleClass];
    }
    
#endif
    
#if RASTERIZE_SHAPES > 0
    //we need better control over this, rasterization is bad news when scaling/rotation without updating the rasterization scale
	if ([_shapeLayer respondsToSelector:@selector(setShouldRasterize:)]) { 
		[_shapeLayer performSelector:@selector(setShouldRasterize:)
					withObject:[NSNumber numberWithBool:YES]];
	}
#endif
	
	return returnLayer;
}

- (void)layoutLayer:(CALayer *)layer {  }

@end
