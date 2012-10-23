//
//  SVGView.h
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SVGDocument;

@interface SVGView : UIView { 
    SVGDocument *_document;
}

@property (nonatomic, retain) SVGDocument *document;
@property (nonatomic, retain) id delegate;

- (id)initWithLayer:(CALayer *)layer andDocument:(SVGDocument *)doc;
- (id)initWithDocument:(SVGDocument *)document; // set frame to position

- (void)addSublayerFromDocument:(SVGDocument *)document;

- (void)removeLayers;
- (void)swapLayer:(CALayer *)layer andDocument:(SVGDocument *)doc;

@end

@protocol SVGViewDelegate <NSObject>

- (void)touchesEnded:(NSSet *)touches inView:(SVGView *)view  withEvent:(UIEvent *)event;

@end
