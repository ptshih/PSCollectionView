What is PSCollectionView?
---
It's a Pinterest style scroll view that resembles familiar paradigms from UITableView.

What is PSCollectionViewCell?
---
It's the equivalent to UITableViewCell
It implements base methods for configuring with data and calculating height

*Note: You should subclass this!*

How does it work?
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