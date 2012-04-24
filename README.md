What is PSCollectionView?
---
It's a Pinterest style scroll view that resembles familiar paradigms from UITableView.

How does it work?
---

`self.collectionView = [[[PSCollectionView alloc] initWithFrame:CGRectMake(0, self.headerView.bottom, self.view.width, self.view.height - self.headerView.height)] autorelease];`
`self.collectionView.delegate = self;`
`self.collectionView.collectionViewDelegate = self;`
`self.collectionView.collectionViewDataSource = self;`
`self.collectionView.backgroundColor = [UIColor clearColor];`
`self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;`