
# Carousel View

*A* navigation control *that* animates a series of elements
either by:
  User clicking a particular element
  User clicking the forward and back arrows

Based on rendering systems:
  VCL
  Firemonkey

Supports:
  Data binding
  Smooth animations and transitions
  Automatic generation of image reflections
  Dynamic addition and removal of items

Structure: (of JvCarouselView)
  Items Container
  Navigation Buttons


# TODO
* On initial design mode:
  Show elliptical path
  Show bottom-wise navigation buttons (bitmap)
* Design mode: (ability to tweak the elliptical path)
  * Ellipse center edit
  * Ellpise attribs edit
  * Scalling (Z)
* Runtine mode:  
  * Move touched item to center
  * Navigation buttons move ite one notch left/right

* Jittering effect when item is stationary
* HighlightSelected
* OwnerData support is not properly implemented
* AlphaSorting is not working
* Thread should slow down when there is no interaction (wasting cycles)

* Have an image reflection below items while rotating
* When items are being added and the carousel is getting crowded then items should be made smaller to avoid overlapping other items
* Better depth painting
* Get missing methods and properties and events from TListView

* Setting background image
* Keyboard hooking for cursor/enter gestures
* Font color is not Used
* Font size is not changed in Z-axis

* Theme support



    property Position: TNavigationPosition read FPosition write FPosition default npMiddle;
    property Theme: TNavigationTheme read FTheme write FTheme default ntLight;
    property Style: TNavigationStyle read FStyle write FStyle default nsDrawn;
    property Bitmap: TPicture read FBitmap write SetBitmap;
