What is PSCollectionView?
---
It's a Pinterest style scroll view that resembles familiar paradigms from UITableView.

How does it work?
---

`self.collectionView = [[[PSCollectionView alloc] initWithFrame:self.view.bounds] autorelease];`

`self.collectionView.delegate = self;`

`self.collectionView.collectionViewDelegate = self;`

`self.collectionView.collectionViewDataSource = self;`

`self.collectionView.backgroundColor = [UIColor clearColor];`

`self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;`