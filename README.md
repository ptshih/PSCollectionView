What is PSCollectionView?
---
It's a Pinterest style scroll view designed to be very similar to UITableView.

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

How to use:
---
Here's an example of creating an instance of PSCollectionView

    self.collectionView = [[[PSCollectionView alloc] initWithFrame:self.view.bounds] autorelease];
    self.collectionView.delegate = self;
    self.collectionView.collectionViewDelegate = self;
    self.collectionView.collectionViewDataSource = self;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

**Setting number of columns**

    // Optionally specify number of columns for both iPhone and iPad
    if (isDeviceIPad()) {
        self.collectionView.numColsPortrait = 4;
        self.collectionView.numColsLandscape = 5;
    } else {
        self.collectionView.numColsPortrait = 2;
        self.collectionView.numColsLandscape = 3;
    }

**Add a loading view or label**

    UIView *loadingLabel = ...
    self.collectionView.loadingView = loadingLabel;

**Add an empty/error view or label**

    UIView *emptyView = ...
    self.collectionView.emptyView = emptyView;

**Add a header view**

    UIView *headerView = ...
    self.collectionView.headerView = headerView;

**Add a footer view**

    UIView *footerView = ...
    self.collectionView.footerView = footerView;

**Delegate and DataSource**

    - (PSCollectionViewCell *)collectionView:(PSCollectionView *)collectionView viewAtIndex:(NSInteger)index {
        NSDictionary *item = [self.items objectAtIndex:index];
        
        // You should probably subclass PSCollectionViewCell
        PSCollectionViewCell *v = (PSCollectionViewCell *)[self.collectionView dequeueReusableView];
        if (!v) {
            v = [[[PSCollectionViewCell alloc] initWithFrame:CGRectZero] autorelease];
        }
        
        [v fillViewWithObject:item]
        
        return v;
    }

    - (CGFloat)heightForViewAtIndex:(NSInteger)index {
        NSDictionary *item = [self.items objectAtIndex:index];

        // You should probably subclass PSCollectionViewCell
        return [PSCollectionViewCell heightForViewWithObject:item inColumnWidth:self.collectionView.colWidth];
    }

    - (void)collectionView:(PSCollectionView *)collectionView didSelectView:(PSCollectionViewCell *)view atIndex:(NSInteger)index {
        // Do something with the tap
    }

License
---
Copyright (C) 2012 Peter Shih. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

* Neither the name of the author nor the names of its contributors may be used
to endorse or promote products derived from this software without specific
prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Questions?
---
Feel free to send me an email if you have any questions implementing PSCollectionView!