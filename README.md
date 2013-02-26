What is PSCollectionView?
---
It's a Pinterest style scroll view designed to be used similar to a UITableView.

It supports Portrait and Landscape orientations.

I built this as a hack to show my friends. Any suggestions or improvements are very welcome!

Coming soon... A fully functional demo app.

What is PSCollectionViewCell?
---
It's the equivalent of UITableViewCell

It implements base methods for configuring data and calculating height

*Note: You should subclass this!*

Want to see this code in a live app?
---
I use this in my iPhone/iPad app, Lunchbox.

[Try it out for free now!](http://itunes.apple.com/us/app/lunchbox/id506544104?mt=8)

[<img src="http://a5.mzstatic.com/us/r1000/086/Purple/v4/b7/08/bb/b708bb3f-0775-67af-6765-e9f17e7384c4/mza_6463307710579208032.480x480-75.jpg" />](http://itunes.apple.com/us/app/lunchbox/id506544104?mt=8)


ARC
---
Fully ARC compatible now

How to use:
---
Here's an example of creating an instance of PSCollectionView

    self.collectionView = [[PSCollectionView alloc] initWithFrame:CGRectZero];
    self.collectionView.delegate = self; // This is for UIScrollViewDelegate
    self.collectionView.collectionViewDelegate = self;
    self.collectionView.collectionViewDataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    self.collectionView.autoresizingMask = ~UIViewAutoresizingNone;

**Setting number of columns**

    // Specify number of columns for both iPhone and iPad
    if (isDeviceIPad()) {
        self.collectionView.numColsPortrait = 3;
        self.collectionView.numColsLandscape = 4;
    } else {
        self.collectionView.numColsPortrait = 1;
        self.collectionView.numColsLandscape = 2;
    }

**Add a header view**

    UIView *headerView = ...
    self.collectionView.headerView = headerView;

**Add a footer view**

    UIView *footerView = ...
    self.collectionView.footerView = footerView;
    
**Reloading Data**
    [self.collectionView reloadData];

**Delegate and DataSource**

    - (Class)collectionView:(PSCollectionView *)collectionView cellClassForRowAtIndex:(NSInteger)index {
        return [PSCollectionViewCell class];
    }

    - (NSInteger)numberOfRowsInCollectionView:(PSCollectionView *)collectionView {
        return 0;
    }

    - (UIView *)collectionView:(PSCollectionView *)collectionView cellForRowAtIndex:(NSInteger)index {
        return nil;
    }

    - (CGFloat)collectionView:(PSCollectionView *)collectionView heightForRowAtIndex:(NSInteger)index {
        return 0.0;
    }

License
---
Copyright (c) 2012 Peter Shih (http://petershih.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

Questions?
---
Feel free to send me an email if you have any questions implementing PSCollectionView!
