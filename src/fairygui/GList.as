package fairygui {
	import laya.display.Sprite;
	import laya.events.Event;
	import laya.maths.Point;
	import laya.maths.Rectangle;
	import laya.utils.Handler;

    public class GList extends GComponent {
        /**
         * itemRenderer(int index, GObject item);
         */
        public var itemRenderer:Handler;
		/**
		 * itemProvider(index:int):String;
		 */
		public var itemProvider:Handler;
		
		public var scrollItemToViewOnClick: Boolean;
		public var foldInvisibleItems:Boolean;
		
        private var _layout: int;
        private var _lineItemCount:int = 0;
        private var _lineGap: int = 0;
        private var _columnGap: int = 0;
        private var _defaultItem: String;
        private var _autoResizeItem: Boolean;
        private var _selectionMode: int;
		private var _align:String;
		private var _verticalAlign:String;
		
        private var _lastSelectedIndex: Number = 0;
        private var _pool: GObjectPool;
        
        //Virtual List support
        private var _virtual:Boolean;
        private var _loop: Boolean;
        private var _numItems: int = 0;
		private var _realNumItems:int;
        private var _firstIndex: int = 0; //the top left index
        private var _curLineItemCount: int = 0; //item count in one line
		private var _curLineItemCount2:int; //只用在页面模式，表示垂直方向的项目数
        private var _itemSize:Point;
        private var _virtualListChanged: int = 0; //1-content changed, 2-size changed
		private var _virtualItems:Vector.<ItemInfo>;
        private var _eventLocked: Boolean;
        
        public function GList() {
            super();

            this._trackBounds = true;
            this._pool = new GObjectPool();
            this._layout = ListLayoutType.SingleColumn;
            this._autoResizeItem = true;
            this._lastSelectedIndex = -1;
            this._selectionMode = ListSelectionMode.Single;
            this.opaque = true;
			this.scrollItemToViewOnClick = true;
			this._align = "left";
			this._verticalAlign = "top";
			
			_container = new Sprite();
			_displayObject.addChild(_container);
        }

        override public function dispose(): void {
            this._pool.clear();
            super.dispose();
        }

        public function get layout(): int {
            return this._layout;
        }

        public function set layout(value: int):void {
            if (this._layout != value) {
                this._layout = value;
                this.setBoundsChangedFlag();
                if(this._virtual)
                    this.setVirtualListChangedFlag(true);
            }
        }

        public function get lineGap(): int {
            return this._lineGap;
        }
        
        public function get lineItemCount(): int {
            return this._lineItemCount;
        }

        public function set lineItemCount(value:int):void {
            if(this._lineItemCount != value) {
                this._lineItemCount = value;
                this.setBoundsChangedFlag();
                if(this._virtual)
                    this.setVirtualListChangedFlag(true);
            }
        }

        public function set lineGap(value: int):void {
            if (this._lineGap != value) {
                this._lineGap = value;
                this.setBoundsChangedFlag();
                if(this._virtual)
                    this.setVirtualListChangedFlag(true);
            }
        }

        public function get columnGap(): int {
            return this._columnGap;
        }

		final public function set columnGap(value:int):void
		{
			if(_columnGap != value)
			{
				_columnGap = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}
		
		public function get align():String
		{
			return _align;
		}
		
		public function set align(value:String):void
		{
			if(_align!=value)
			{
				_align = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}
		
		final public function get verticalAlign():String
		{
			return _verticalAlign;
		}
		
		public function set verticalAlign(value:String):void
		{
			if(_verticalAlign!=value)
			{
				_verticalAlign = value;
				setBoundsChangedFlag();
				if (_virtual)
					setVirtualListChangedFlag(true);
			}
		}
        
        public function get virtualItemSize(): Point  {
            return this._itemSize;
        }

        public function set virtualItemSize(value: Point):void {
            if(this._virtual) {
                if(this._itemSize == null)
                    this._itemSize = new Point();
                this._itemSize.setTo(value.x, value.y);
                this.setVirtualListChangedFlag(true);
            }
        }

        public function get defaultItem(): String {
            return this._defaultItem;
        }

        public function set defaultItem(val: String):void {
            this._defaultItem = val;
        }

        public function get autoResizeItem(): Boolean {
            return this._autoResizeItem;
        }

        public function set autoResizeItem(value: Boolean):void {
            this._autoResizeItem = value;
        }

        public function get selectionMode(): int {
            return this._selectionMode;
        }

        public function set selectionMode(value: int):void {
            this._selectionMode = value;
        }

		public function get itemPool():GObjectPool
		{
			return this._pool;
		}

        public function getFromPool(url: String= null): GObject {
            if (!url)
                url = this._defaultItem;

            var obj:GObject = this._pool.getObject(url);
            if(obj!=null)
                obj.visible = true;
            return obj;
        }

        public function returnToPool(obj: GObject): void {
            obj.displayObject.cacheAsBitmap = false;
            this._pool.returnObject(obj);
        }

        override public function addChildAt(child: GObject, index: Number = 0): GObject {
            if (this._autoResizeItem) {
                if (this._layout == ListLayoutType.SingleColumn)
                    child.width = this.viewWidth;
                else if (this._layout == ListLayoutType.SingleRow)
                    child.height = this.viewHeight;
            }

            super.addChildAt(child, index);

            if (child is GButton) {
                var button: GButton = GButton(child);
                button.selected = false;
                button.changeStateOnClick = false;
            }
            child.on(Event.CLICK, this, this.__clickItem);

            return child;
        }

        public function addItem(url: String= null): GObject {
            if (!url)
                url = this._defaultItem;

            return this.addChild(UIPackage.createObjectFromURL(url));
        }

        public function addItemFromPool(url: String= null): GObject {
            return this.addChild(this.getFromPool(url));
        }

        override public function removeChildAt(index: Number, dispose: Boolean= false): GObject {
            var child: GObject = super.removeChildAt(index, dispose);
            child.off(Event.CLICK, this, this.__clickItem);

            return child;
        }

        public function removeChildToPoolAt(index: Number = 0): void {
            var child: GObject = super.removeChildAt(index);
            this.returnToPool(child);
        }

        public function removeChildToPool(child: GObject): void {
            super.removeChild(child);
            this.returnToPool(child);
        }

        public function removeChildrenToPool(beginIndex: Number= 0, endIndex: Number= -1): void {
            if (endIndex < 0 || endIndex >= this._children.length)
                endIndex = this._children.length - 1;

            for (var i: Number = beginIndex; i <= endIndex; ++i)
                this.removeChildToPoolAt(beginIndex);
        }

        public function get selectedIndex(): Number {
            var cnt: Number = this._children.length;
            for (var i: Number = 0; i < cnt; i++) {
                var obj: GObject = this._children[i];
                if ((obj is GButton) && GButton(obj).selected)
					return childIndexToItemIndex(i);
            }
            return -1;
        }

        public function set selectedIndex(value: Number):void {
            this.clearSelection();
            if (value >= 0 && value < this.numItems)
                this.addSelection(value);
        }

        public function getSelection(): Vector.<Number> {
            var ret: Vector.<Number> = new Vector.<Number>();
            var cnt: Number = this._children.length;
            for (var i: Number = 0; i < cnt; i++) {
                var obj: GObject = this._children[i];
				if ((obj is GButton) && GButton(obj).selected)
					ret.push(childIndexToItemIndex(i));
            }
            return ret;
        }

        public function addSelection(index: Number, scrollItToView: Boolean= false): void {
            if (this._selectionMode == ListSelectionMode.None)
                return;
			
			this.checkVirtualList();

            if (this._selectionMode == ListSelectionMode.Single)
                this.clearSelection();
                
            if(scrollItToView)
                this.scrollToView(index);

			index = itemIndexToChildIndex(index);
            if(index<0 || index >= this._children.length)
                return;

            var obj: GObject = this.getChildAt(index);
			if ((obj is GButton) && !GButton(obj).selected)
				GButton(obj).selected = true;
        }

        public function removeSelection(index: Number = 0): void {
            if (this._selectionMode == ListSelectionMode.None)
                return;

			index = itemIndexToChildIndex(index);
            if(index >= this._children.length)
                return;

            var obj: GObject = this.getChildAt(index);
			if ((obj is GButton) && GButton(obj).selected)
				GButton(obj).selected = false;
        }

        public function clearSelection(): void {
            var cnt: Number = this._children.length;
            for (var i: Number = 0; i < cnt; i++) {
                var obj: GObject = this._children[i];
                if (obj is GButton)
					GButton(obj).selected = false;
            }
        }

        public function selectAll(): void {
			this.checkVirtualList();
			
            var cnt: Number = this._children.length;
            for (var i: Number = 0; i < cnt; i++) {
                var obj: GObject = this._children[i];
				if (obj is GButton)
					GButton(obj).selected = true;
            }
        }

        public function selectNone(): void {
			this.checkVirtualList();
			
            var cnt: Number = this._children.length;
            for (var i: Number = 0; i < cnt; i++) {
                var obj: GObject = this._children[i];
				if (obj is GButton)
					GButton(obj).selected = false;
            }
        }

        public function selectReverse(): void {
            var cnt: Number = this._children.length;
            for (var i: Number = 0; i < cnt; i++) { 
                var obj: GObject = this._children[i];
				if (obj is GButton)
					GButton(obj).selected = !GButton(obj).selected;
            }
        }

        public function handleArrowKey(dir: Number = 0): void {
            var index: Number = this.selectedIndex;
            if (index == -1)
                return;

            switch (dir) {
                case 1://up
                    if (this._layout == ListLayoutType.SingleColumn || this._layout == ListLayoutType.FlowVertical) {
                        index--;
                        if (index >= 0) {
                            this.clearSelection();
                            this.addSelection(index, true);
                        }
                    }
					else if (_layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination) {
                        var current: GObject = this._children[index];
                        var k: Number = 0;
                        for (var i: Number = index - 1; i >= 0; i--) {
                            var obj: GObject = this._children[i];
                            if (obj.y != current.y) {
                                current = obj;
                                break;
                            }
                            k++;
                        }
                        for (; i >= 0; i--) {
                            obj = this._children[i];
                            if (obj.y != current.y) {
                                this.clearSelection();
                                this.addSelection(i + k + 1, true);
                                break;
                            }
                        }
                    }
                    break;

                case 3://right
					if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination) {
                        index++;
                        if (index < this._children.length) {
                            this.clearSelection();
                            this.addSelection(index, true);
                        }
                    }
                    else if (this._layout == ListLayoutType.FlowVertical) {
                        current = this._children[index];
                        k = 0;
                        var cnt: Number = this._children.length;
                        for (i = index + 1; i < cnt; i++) {
                            obj = this._children[i];
                            if (obj.x != current.x) {
                                current = obj;
                                break;
                            }
                            k++;
                        }
                        for (; i < cnt; i++) {
                            obj = this._children[i];
                            if (obj.x != current.x) {
                                this.clearSelection();
                                this.addSelection(i - k - 1, true);
                                break;
                            }
                        }
                    }
                    break;

                case 5://down
                    if (this._layout == ListLayoutType.SingleColumn || this._layout == ListLayoutType.FlowVertical) {
                        index++;
                        if (index < this._children.length) {
                            this.clearSelection();
                            this.addSelection(index, true);
                        }
                    }
					else if (_layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination) {
                        current = this._children[index];
                        k = 0;
                        cnt = this._children.length;
                        for (i = index + 1; i < cnt; i++) {
                            obj = this._children[i];
                            if (obj.y != current.y) {
                                current = obj;
                                break;
                            }
                            k++;
                        }
                        for (; i < cnt; i++) {
                            obj = this._children[i];
                            if (obj.y != current.y) {
                                this.clearSelection();
                                this.addSelection(i - k - 1, true);
                                break;
                            }
                        }
                    }
                    break;

                case 7://left
					if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination) {
                        index--;
                        if (index >= 0) {
                            this.clearSelection();
                            this.addSelection(index, true);
                        }
                    }
                    else if (this._layout == ListLayoutType.FlowVertical) {
                        current = this._children[index];
                        k = 0;
                        for (i = index - 1; i >= 0; i--) {
                            obj = this._children[i];
                            if (obj.x != current.x) {
                                current = obj;
                                break;
                            }
                            k++;
                        }
                        for (; i >= 0; i--) {
                            obj = this._children[i];
                            if (obj.x != current.x) {
                                this.clearSelection();
                                this.addSelection(i + k + 1, true);
                                break;
                            }
                        }
                    }
                    break;
            }
        }

        private function __clickItem(evt:Event): void {
            if (this._scrollPane != null && this._scrollPane.isDragged)
                return;

            var item: GObject = GObject.cast(evt.currentTarget);
           	this.setSelectionOnEvent(item, evt);

            if(this._scrollPane && scrollItemToViewOnClick)
                this._scrollPane.scrollToView(item,true);

            this.displayObject.event(Events.CLICK_ITEM, [item, Events.createEvent(Events.CLICK_ITEM, this.displayObject,evt)]);
        }

        private function setSelectionOnEvent(item: GObject, evt:Event): void {
            if (!(item is GButton) || this._selectionMode == ListSelectionMode.None)
                return;

            var dontChangeLastIndex: Boolean = false;
            var button: GButton = GButton(item);
            var index: Number = this.getChildIndex(item);
            
            if (this._selectionMode == ListSelectionMode.Single) {
                if (!button.selected) {
                    this.clearSelectionExcept(button);
                    button.selected = true;
                }
            }
            else {
                if (evt.shiftKey) {
                    if (!button.selected) {
                        if (this._lastSelectedIndex != -1) {
                            var min: Number = Math.min(this._lastSelectedIndex, index);
                            var max: Number = Math.max(this._lastSelectedIndex, index);
                            max = Math.min(max,this._children.length - 1);
                            for (var i: Number = min; i <= max; i++) {
                                var obj: GObject = this.getChildAt(i);
                                if ((obj is GButton) && !GButton(obj).selected)
									GButton(obj).selected = true;
                            }

                            dontChangeLastIndex = true;
                        }
                        else {
                            button.selected = true;
                        }
                    }
                }
                else if (evt.ctrlKey || this._selectionMode == ListSelectionMode.Multiple_SingleClick) {
                    button.selected = !button.selected;
                }
                else {
                    if (!button.selected) {
                        this.clearSelectionExcept(button);
                        button.selected = true;
                    }
                    else
                        this.clearSelectionExcept(button);
                }
            }

            if (!dontChangeLastIndex)
                this._lastSelectedIndex = index;

            return;
        }

        private function clearSelectionExcept(obj: GObject): void {
            var cnt: Number = this._children.length;
            for (var i: Number = 0; i < cnt; i++) {
                var button: GObject = this._children[i];
                if ((button is GButton) && button != obj && GButton(button).selected)
					GButton(button).selected = false;
            }
        }

        public function resizeToFit(itemCount: Number = 1000000, minSize: Number = 0): void {
            this.ensureBoundsCorrect();

            var curCount: Number = this.numItems;
            if (itemCount > curCount)
                itemCount = curCount;

            if(this._virtual) {
                var lineCount: Number = Math.ceil(itemCount / this._curLineItemCount);
                if(this._layout == ListLayoutType.SingleColumn || this._layout == ListLayoutType.FlowHorizontal)
                    this.viewHeight = lineCount * this._itemSize.y + Math.max(0,lineCount - 1) * this._lineGap;
                else
                    this.viewWidth = lineCount * this._itemSize.x + Math.max(0,lineCount - 1) * this._columnGap;
            }
            else if(itemCount == 0) {
                if (this._layout == ListLayoutType.SingleColumn || this._layout == ListLayoutType.FlowHorizontal)
                    this.viewHeight = minSize;
                else
                    this.viewWidth = minSize;
            }
            else {
                var i: Number = itemCount - 1;
                var obj: GObject = null;
                while (i >= 0) {
                    obj = this.getChildAt(i);
                    if (!foldInvisibleItems || obj.visible)
                        break;
                    i--;
                }
                if (i < 0) {
                    if (this._layout == ListLayoutType.SingleColumn || this._layout == ListLayoutType.FlowHorizontal)
                        this.viewHeight = minSize;
                    else
                        this.viewWidth = minSize;
                }
                else {
                    var size: Number = 0;
                    if (this._layout == ListLayoutType.SingleColumn || this._layout == ListLayoutType.FlowHorizontal) {
                        size = obj.y + obj.height;
                        if (size < minSize)
                            size = minSize;
                        this.viewHeight = size;
                    }
                    else {
                        size = obj.x + obj.width;
                        if (size < minSize)
                            size = minSize;
                        this.viewWidth = size;
                    }
                }
            }
        }

        public function getMaxItemWidth(): Number {
            var cnt: Number = this._children.length;
            var max: Number = 0;
            for (var i: Number = 0; i < cnt; i++) {
                var child: GObject = this.getChildAt(i);
                if (child.width > max)
                    max = child.width;
            }
            return max;
        }

        override protected function handleSizeChanged(): void {
            super.handleSizeChanged();

            if (this._autoResizeItem)
                this.adjustItemsSize();

            if (this._layout == ListLayoutType.FlowHorizontal || this._layout == ListLayoutType.FlowVertical) {
                this.setBoundsChangedFlag();
            	if (this._virtual)
                    this.setVirtualListChangedFlag(true);
		    }
        }

        public function adjustItemsSize(): void {
            if (this._layout == ListLayoutType.SingleColumn) {
                var cnt: Number = this._children.length;
                var cw: Number = this.viewWidth;
                for (var i: Number = 0; i < cnt; i++) {
                    var child: GObject = this.getChildAt(i);
                    child.width = cw;
                }
            }
            else if (this._layout == ListLayoutType.SingleRow) {
                cnt = this._children.length;
                var ch: Number = this.viewHeight;
                for (i = 0; i < cnt; i++) {
                    child = this.getChildAt(i);
                    child.height = ch;
                }
            }
        }

		override public function getSnappingPosition(xValue:Number, yValue:Number, resultPoint:Point=null):Point
		{
			if (_virtual)
			{
				if(!resultPoint)
					resultPoint = new Point();
				
				var saved:Number;
				var index:int;
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					saved = yValue;
					GList.pos_param = yValue;
					index = getIndexOnPos1(false);
					yValue = GList.pos_param;
					if (index < _virtualItems.length && saved - yValue > _virtualItems[index].height / 2 && index < _realNumItems)
						yValue += _virtualItems[index].height + _lineGap;
				}
				else if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowVertical)
				{
					saved = xValue;
					GList.pos_param = xValue;
					index = getIndexOnPos2(false);
					xValue = GList.pos_param;
					if (index < _virtualItems.length && saved - xValue > _virtualItems[index].width / 2 && index < _realNumItems)
						xValue += _virtualItems[index].width + _columnGap;
				}
				else
				{
					saved = xValue;
					GList.pos_param = xValue;
					index = getIndexOnPos3(false);
					xValue = GList.pos_param;
					if (index < _virtualItems.length && saved - xValue > _virtualItems[index].width / 2 && index < _realNumItems)
						xValue += _virtualItems[index].width + _columnGap;
				}
				
				resultPoint.x = xValue;
				resultPoint.y = yValue;
				return resultPoint;
			}
			else
				return super.getSnappingPosition(xValue, yValue, resultPoint);
		}
        
		public function scrollToView(index:int, ani:Boolean=false, setFirst:Boolean=false):void
		{
			if (_virtual)
			{
				if(_numItems==0)
					return;
				
				checkVirtualList();
				
				if (index >= _virtualItems.length)
					throw new Error("Invalid child index: " + index + ">" + _virtualItems.length);
				
				if(_loop)
					index = Math.floor(_firstIndex/_numItems)*_numItems+index;
				
				var rect:Rectangle;
				var ii:ItemInfo = _virtualItems[index];
				var pos:Number = 0;
				var i:int;
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					for (i = 0; i < index; i += _curLineItemCount)
						pos += _virtualItems[i].height + _lineGap;
					rect = new Rectangle(0, pos, _itemSize.x, ii.height);
				}
				else if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowVertical)
				{
					for (i = 0; i < index; i += _curLineItemCount)
						pos += _virtualItems[i].width + _columnGap;
					rect = new Rectangle(pos, 0, ii.width, _itemSize.y);
				}
				else
				{
					var page:int = index / (_curLineItemCount * _curLineItemCount2);
					rect = new Rectangle(page * viewWidth + (index % _curLineItemCount) * (ii.width + _columnGap),
						(index / _curLineItemCount) % _curLineItemCount2 * (ii.height + _lineGap),
						ii.width, ii.height);
				}
				
				setFirst = true;//因为在可变item大小的情况下，只有设置在最顶端，位置才不会因为高度变化而改变，所以只能支持setFirst=true
				if (_scrollPane != null)
					scrollPane.scrollToView(rect, ani, setFirst);
			}
			else
			{
				var obj:GObject = getChildAt(index);
				if (_scrollPane != null)
					scrollPane.scrollToView(obj, ani, setFirst);
				else if (parent != null && parent.scrollPane != null)
					parent.scrollPane.scrollToView(obj, ani, setFirst);
			}
		}
		
		override public function getFirstChildInView():int
		{
			return childIndexToItemIndex(super.getFirstChildInView());
		}
		
		public function childIndexToItemIndex(index:int):int
		{
			if (!_virtual)
				return index;
			
			if (_layout == ListLayoutType.Pagination)
			{
				for (var i:int = _firstIndex; i < _realNumItems; i++)
				{
					if (_virtualItems[i].obj != null)
					{
						index--;
						if (index < 0)
							return i;
					}
				}
				
				return index;
			}
			else
			{
				index += _firstIndex;
				if (_loop && _numItems > 0)
					index = index % _numItems;
				
				return index;
			}
		}
		
		public function itemIndexToChildIndex(index:int):int
		{
			if (!_virtual)
				return index;
			
			if (_layout == ListLayoutType.Pagination)
			{
				return getChildIndex(_virtualItems[index].obj);
			}
			else
			{
				if (_loop && _numItems > 0)
				{
					var j:int = _firstIndex % _numItems;
					if (index >= j)
						index = _firstIndex + (index - j);
					else
						index = _firstIndex + _numItems + (j - index);
				}
				else
					index -= _firstIndex;
				
				return index;
			}
		}
    
        public function setVirtual(): void {
            this._setVirtual(false);
        }
		
        /// <summary>
        /// Set the list to be virtual list, and has loop behavior.
        /// </summary>
        public function setVirtualAndLoop(): void {
            this._setVirtual(true);
        }
		
        /// <summary>
        /// Set the list to be virtual list.
        /// </summary>
        private function _setVirtual(loop: Boolean): void {
            if(!this._virtual) {
                if(this._scrollPane == null)
                    throw new Error("Virtual list must be scrollable!");
                    
                if(loop) {        
                    if(this._layout == ListLayoutType.FlowHorizontal || this._layout == ListLayoutType.FlowVertical)
                        throw new Error("Loop list is not supported for FlowHorizontal or FlowVertical layout!");
        
                    this._scrollPane.bouncebackEffect = false;
                }
        
                this._virtual = true;
                this._loop = loop;
				this._virtualItems = new Vector.<ItemInfo>();
                this.removeChildrenToPool();
        
                if(this._itemSize==null) {
                    this._itemSize = new Point();
                    var obj: GObject = this.getFromPool(null);
					if (obj == null)
					{
						throw new Error("Virtual List must have a default list item resource.");
					}
					else
					{
                    	this._itemSize.x = obj.width;
                    	this._itemSize.y = obj.height;
					}
                    this.returnToPool(obj);
                }
        
                if(this._layout == ListLayoutType.SingleColumn || this._layout == ListLayoutType.FlowHorizontal)
                    this._scrollPane.scrollSpeed = this._itemSize.y;
                else
                    this._scrollPane.scrollSpeed = this._itemSize.x;
        
                this.on(Events.SCROLL, this, this.__scrolled);
                this.setVirtualListChangedFlag(true);
            }
        }
        		
        /// <summary>
        /// Set the list item count. 
        /// If the list is not virtual, specified Number of items will be created. 
        /// If the list is virtual, only items in view will be created.
        /// </summary>
        public function get numItems():int
        {
            if(this._virtual)
                return this._numItems;
            else
                return this._children.length;
        }
        
		public function set numItems(value:int):void
		{
			var i:int;
			
			if (_virtual)
			{
				if (itemRenderer == null)
					throw new Error("Set itemRenderer first!");
				
				_numItems = value;
				if (_loop)
					_realNumItems = _numItems * 5;//设置5倍数量，用于循环滚动
				else
					_realNumItems = _numItems;
				
				//_virtualItems的设计是只增不减的
				var oldCount:int = _virtualItems.length;
				if (_realNumItems > oldCount)
				{
					for (i = oldCount; i < _realNumItems; i++)
					{
						var ii:ItemInfo = new ItemInfo();
						ii.width = _itemSize.x;
						ii.height = _itemSize.y;
						
						_virtualItems.push(ii);
					}
				}
				
				if (this._virtualListChanged != 0)
					Laya.timer.clear(this, this._refreshVirtualList);
				
				//立即刷新
				_refreshVirtualList();
			}
			else
			{
				var cnt:int = _children.length;
				if (value > cnt)
				{
					for (i = cnt; i < value; i++)
					{
						if (itemProvider == null)
							addItemFromPool();
						else
							addItemFromPool(itemProvider.runWith(i));
					}
				}
				else
				{
					removeChildrenToPool(value, cnt);
				}
				
				if (itemRenderer != null)
				{
					for (i = 0; i < value; i++)
						itemRenderer.runWith([i, getChildAt(i)]);
				}
			}
		}
        
		public function refreshVirtualList():void
		{
			this.setVirtualListChangedFlag(false);
		}
		
		private function checkVirtualList():void
		{
			if(this._virtualListChanged!=0) { 
				this._refreshVirtualList();
				Laya.timer.clear(this, this._refreshVirtualList);
			}
		}
        
        private function setVirtualListChangedFlag(layoutChanged:Boolean = false):void {
            if(layoutChanged)
                this._virtualListChanged = 2;
            else if(this._virtualListChanged == 0)
                this._virtualListChanged = 1;
    
            Laya.timer.callLater(this, this._refreshVirtualList);
        }
        
        private function _refreshVirtualList(): void {
			var layoutChanged:Boolean = _virtualListChanged == 2;
			_virtualListChanged = 0;
			_eventLocked = true;
			
			if (layoutChanged)
			{
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.SingleRow)
					_curLineItemCount = 1;
				else if (_lineItemCount != 0)
					_curLineItemCount = _lineItemCount;
				else if (_layout == ListLayoutType.FlowHorizontal)
				{
					_curLineItemCount = Math.floor((_scrollPane.viewWidth + _columnGap) / (_itemSize.x + _columnGap));
					if (_curLineItemCount <= 0)
						_curLineItemCount = 1;
				}
				else if (_layout == ListLayoutType.FlowVertical)
				{
					_curLineItemCount = Math.floor((_scrollPane.viewHeight + _lineGap) / (_itemSize.y + _lineGap));
					if (_curLineItemCount <= 0)
						_curLineItemCount = 1;
				}
				else //pagination
				{
					_curLineItemCount = Math.floor((_scrollPane.viewWidth + _columnGap) / (_itemSize.x + _columnGap));
					if (_curLineItemCount <= 0)
						_curLineItemCount = 1;
				}
				
				if (_layout == ListLayoutType.Pagination)
				{
					_curLineItemCount2 = Math.floor((_scrollPane.viewHeight + _lineGap) / (_itemSize.y + _lineGap));
					if (_curLineItemCount2 <= 0)
						_curLineItemCount2 = 1;
				}
			}
			
			var ch:Number = 0, cw:Number = 0;
			if (_realNumItems > 0)
			{
				var i:int;
				var len:int = Math.ceil(_realNumItems / _curLineItemCount) * _curLineItemCount;
				if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
				{
					for (i = 0; i < len; i += _curLineItemCount)
						ch += _virtualItems[i].height + _lineGap;
					if (ch > 0)
						ch -= _lineGap;
					cw = _scrollPane.contentWidth;
				}
				else if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowVertical)
				{
					for (i = 0; i < len; i += _curLineItemCount)
						cw += _virtualItems[i].width + _columnGap;
					if (cw > 0)
						cw -= _columnGap;
					ch = _scrollPane.contentHeight;
				}
				else
				{
					var pageCount:int = Math.ceil(len / (_curLineItemCount * _curLineItemCount2));
					cw = pageCount * viewWidth;
					ch = viewHeight;
				}
			}
			
			handleAlign(cw, ch);
			_scrollPane.setContentSize(cw, ch);
			
			_eventLocked = false;
			
			handleScroll(true);
        }
        
		private function __scrolled(evt:Event):void
		{
			handleScroll(false);
		}
		
		private function getIndexOnPos1(forceUpdate:Boolean):int
		{
			if (_realNumItems < _curLineItemCount)
			{
				pos_param = 0;
				return 0;
			}
			
			var i:int;
			var pos2:Number;
			var pos3:Number;
			
			if (numChildren > 0 && !forceUpdate)
			{
				pos2 = this.getChildAt(0).y;
				if (pos2 > pos_param)
				{
					for (i = _firstIndex - _curLineItemCount; i >= 0; i -= _curLineItemCount)
					{
						pos2 -= (_virtualItems[i].height + _lineGap);
						if (pos2 <= pos_param)
						{
							pos_param = pos2;
							return i;
						}
					}
					
					pos_param = 0;
					return 0;
				}
				else
				{
					for (i = _firstIndex; i < _realNumItems; i += _curLineItemCount)
					{
						pos3 = pos2 + _virtualItems[i].height + _lineGap;
						if (pos3 > pos_param)
						{
							pos_param = pos2;
							return i;
						}
						pos2 = pos3;
					}
					
					pos_param = pos2;
					return _realNumItems - _curLineItemCount;
				}
			}
			else
			{
				pos2 = 0;
				for (i = 0; i < _realNumItems; i += _curLineItemCount)
				{
					pos3 = pos2 + _virtualItems[i].height + _lineGap;
					if (pos3 > pos_param)
					{
						pos_param = pos2;
						return i;
					}
					pos2 = pos3;
				}
				
				pos_param = pos2;
				return _realNumItems - _curLineItemCount;
			}
		}
		
		private function getIndexOnPos2(forceUpdate:Boolean):int
		{
			if (_realNumItems < _curLineItemCount)
			{
				pos_param = 0;
				return 0;
			}
			
			var i:int;
			var pos2:Number;
			var pos3:Number;
			
			if (numChildren > 0 && !forceUpdate)
			{
				pos2 = this.getChildAt(0).x;
				if (pos2 > pos_param)
				{
					for (i = _firstIndex - _curLineItemCount; i >= 0; i -= _curLineItemCount)
					{
						pos2 -= (_virtualItems[i].width + _columnGap);
						if (pos2 <= pos_param)
						{
							pos_param = pos2;
							return i;
						}
					}
					
					pos_param = 0;
					return 0;
				}
				else
				{
					for (i = _firstIndex; i < _realNumItems; i += _curLineItemCount)
					{
						pos3 = pos2 + _virtualItems[i].width + _columnGap;
						if (pos3 > pos_param)
						{
							pos_param = pos2;
							return i;
						}
						pos2 = pos3;
					}
					
					pos_param = pos2;
					return _realNumItems - _curLineItemCount;
				}
			}
			else
			{
				pos2 = 0;
				for (i = 0; i < _realNumItems; i += _curLineItemCount)
				{
					pos3 = pos2 + _virtualItems[i].width + _columnGap;
					if (pos3 > pos_param)
					{
						pos_param = pos2;
						return i;
					}
					pos2 = pos3;
				}
				
				pos_param = pos2;
				return _realNumItems - _curLineItemCount;
			}
		}
		
		private function getIndexOnPos3(forceUpdate:Boolean):int
		{
			if (_realNumItems < _curLineItemCount)
			{
				pos_param = 0;
				return 0;
			}
			
			var viewWidth:Number = this.viewWidth;
			var page:int = Math.floor(pos_param / viewWidth);
			var startIndex:int = page * (_curLineItemCount * _curLineItemCount2);
			var pos2:Number = page * viewWidth;
			var i:int;
			var pos3:Number;
			for (i = 0; i < _curLineItemCount; i++)
			{
				pos3 = pos2 + _virtualItems[startIndex + i].width + _columnGap;
				if (pos3 > pos_param)
				{
					pos_param = pos2;
					return startIndex + i;
				}
				pos2 = pos3;
			}
			
			pos_param = pos2;
			return startIndex + _curLineItemCount - 1;
		}
		
		private function handleScroll(forceUpdate:Boolean):void
		{
			if (_eventLocked)
				return;
			
			var pos:Number;
			var roundSize:int;
			
			if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal)
			{
				if (_loop)
				{
					pos = scrollPane.scrollingPosY;
					//循环列表的核心实现，滚动到头尾时重新定位
					roundSize = _numItems * (_itemSize.y + _lineGap);
					if (pos == 0)
						scrollPane.posY = roundSize;
					else if (pos == scrollPane.contentHeight - scrollPane.viewHeight)
						scrollPane.posY = scrollPane.contentHeight - roundSize - this.viewHeight;
				}
				
				handleScroll1(forceUpdate);
			}
			else if (_layout == ListLayoutType.SingleRow || _layout == ListLayoutType.FlowVertical)
			{
				if (_loop)
				{
					pos = scrollPane.scrollingPosX;
					//循环列表的核心实现，滚动到头尾时重新定位
					roundSize = _numItems * (_itemSize.x + _columnGap);
					if (pos == 0)
						scrollPane.posX = roundSize;
					else if (pos == scrollPane.contentWidth - scrollPane.viewWidth)
						scrollPane.posX = scrollPane.contentWidth - roundSize - this.viewWidth;
				}
				
				handleScroll2(forceUpdate);
			}
			else
			{
				if (_loop)
				{
					pos = scrollPane.scrollingPosX;
					//循环列表的核心实现，滚动到头尾时重新定位
					roundSize = Math.floor(_numItems / (_curLineItemCount * _curLineItemCount2)) * viewWidth;
					if (pos == 0)
						scrollPane.posX = roundSize;
					else if (pos == scrollPane.contentWidth - scrollPane.viewWidth)
						scrollPane.posX = scrollPane.contentWidth - roundSize - this.viewWidth;
				}
				
				handleScroll3(forceUpdate);
			}
			
			_boundsChanged = false;
		}
		
		private static var itemInfoVer:uint = 0; //用来标志item是否在本次处理中已经被重用了
		private static var enterCounter:uint = 0; //因为HandleScroll是会重入的，这个用来避免极端情况下的死锁
		private static var pos_param:Number;
		
		private function handleScroll1(forceUpdate:Boolean):void
		{
			enterCounter++;
			if (enterCounter > 3)
				return;
			
			var pos:Number = scrollPane.scrollingPosY;
			var max:Number = pos + scrollPane.viewHeight;
			var end:Boolean = max == scrollPane.contentHeight;//这个标志表示当前需要滚动到最末，无论内容变化大小
			
			//寻找当前位置的第一条项目
			GList.pos_param = pos;
			var newFirstIndex:int = getIndexOnPos1(forceUpdate);
			pos = GList.pos_param;
			if (newFirstIndex == _firstIndex && !forceUpdate)
			{
				enterCounter--;
				return;
			}
			
			var oldFirstIndex:int = _firstIndex;
			_firstIndex = newFirstIndex;
			var curIndex:int = newFirstIndex;
			var forward:Boolean = oldFirstIndex > newFirstIndex;
			var oldCount:int = this.numChildren;
			var lastIndex:int = oldFirstIndex + oldCount - 1;
			var reuseIndex:int = forward ? lastIndex : oldFirstIndex;
			var curX:Number = 0, curY:Number = pos;
			var needRender:Boolean;
			var deltaSize:Number = 0;
			var firstItemDeltaSize:Number = 0;
			var url:String = defaultItem;
			var ii:ItemInfo, ii2:ItemInfo;
			var i:int,j:int;
			
			itemInfoVer++;
			
			while (curIndex < _realNumItems && (end || curY < max))
			{
				ii = _virtualItems[curIndex];
				
				if (ii.obj == null || forceUpdate)
				{
					if (itemProvider != null)
					{
						url = itemProvider.runWith(curIndex % _numItems);
						if (url == null)
							url = defaultItem;
					}
					
					if (ii.obj != null && ii.obj.resourceURL != url)
					{
						removeChildToPool(ii.obj);
						ii.obj = null;
					}
				}
				
				if (ii.obj == null)
				{
					//搜索最适合的重用item，保证每次刷新需要新建或者重新render的item最少
					if (forward)
					{
						for (j = reuseIndex; j >= oldFirstIndex; j--)
						{
							ii2 = _virtualItems[j];
							if (ii2.obj != null && ii2.updateFlag != itemInfoVer && ii2.obj.resourceURL == url)
							{
								ii.obj = ii2.obj;
								ii2.obj = null;
								if (j == reuseIndex)
									reuseIndex--;
								break;
							}
						}
					}
					else
					{
						for (j = reuseIndex; j <= lastIndex; j++)
						{
							ii2 = _virtualItems[j];
							if (ii2.obj != null && ii2.updateFlag != itemInfoVer && ii2.obj.resourceURL == url)
							{
								ii.obj = ii2.obj;
								ii2.obj = null;
								if (j == reuseIndex)
									reuseIndex++;
								break;
							}
						}
					}
					
					if (ii.obj != null)
					{
						setChildIndex(ii.obj, forward ? curIndex - newFirstIndex : numChildren);
					}
					else
					{
						ii.obj = _pool.getObject(url);
						if (forward)
							this.addChildAt(ii.obj, curIndex - newFirstIndex);
						else
							this.addChild(ii.obj);
					}
					if (ii.obj is GButton)
						GButton(ii.obj).selected = false;
					
					needRender = true;
				}
				else
					needRender = forceUpdate;
				
				if (needRender)
				{
					itemRenderer.runWith([curIndex % _numItems, ii.obj]);
					if (curIndex % _curLineItemCount == 0)
					{
						deltaSize += Math.ceil(ii.obj.height) - ii.height;
						if (curIndex == newFirstIndex && oldFirstIndex > newFirstIndex)
						{
							//当内容向下滚动时，如果新出现的项目大小发生变化，需要做一个位置补偿，才不会导致滚动跳动
							firstItemDeltaSize = Math.ceil(ii.obj.height) - ii.height;
						}
					}
					ii.width = Math.ceil(ii.obj.width);
					ii.height = Math.ceil(ii.obj.height);
				}
				
				ii.updateFlag = itemInfoVer;
				ii.obj.setXY(curX, curY);
				if (curIndex == newFirstIndex) //要显示多一条才不会穿帮
					max += ii.height;
				
				curX += ii.width + _columnGap;
				
				if (curIndex % _curLineItemCount == _curLineItemCount - 1)
				{
					curX = 0;
					curY += ii.height + _lineGap;
				}
				curIndex++;
			}
			
			for (i = 0; i < oldCount; i++)
			{
				ii = _virtualItems[oldFirstIndex + i];
				if (ii.updateFlag != itemInfoVer && ii.obj != null)
				{
					removeChildToPool(ii.obj);
					ii.obj = null;
				}
			}
			
			if (deltaSize != 0 || firstItemDeltaSize != 0)
				_scrollPane.changeContentSizeOnScrolling(0, deltaSize, 0, firstItemDeltaSize);
			
			if (curIndex > 0 && this.numChildren > 0 && _container.y < 0 && getChildAt(0).y > -_container.y)//最后一页没填满！
				handleScroll1(false);
			
			enterCounter--;
		}
		
		private function handleScroll2(forceUpdate:Boolean):void
		{
			enterCounter++;
			if (enterCounter > 3)
				return;
			
			var pos:Number = scrollPane.scrollingPosX;
			var max:Number = pos + scrollPane.viewWidth;
			var end:Boolean = pos == scrollPane.contentWidth;//这个标志表示当前需要滚动到最末，无论内容变化大小
			
			//寻找当前位置的第一条项目
			GList.pos_param = pos;
			var newFirstIndex:int = getIndexOnPos2(forceUpdate);
			pos = GList.pos_param;
			if (newFirstIndex == _firstIndex && !forceUpdate)
			{
				enterCounter--;
				return;
			}
			
			var oldFirstIndex:int = _firstIndex;
			_firstIndex = newFirstIndex;
			var curIndex:int = newFirstIndex;
			var forward:Boolean = oldFirstIndex > newFirstIndex;
			var oldCount:int = this.numChildren;
			var lastIndex:int = oldFirstIndex + oldCount - 1;
			var reuseIndex:int = forward ? lastIndex : oldFirstIndex;
			var curX:Number = pos, curY:Number = 0;
			var needRender:Boolean;
			var deltaSize:Number = 0;
			var firstItemDeltaSize:Number  = 0;
			var url:String = defaultItem;
			var ii:ItemInfo, ii2:ItemInfo;
			var i:int,j:int;
			
			itemInfoVer++;
			
			while (curIndex < _realNumItems && (end || curX < max))
			{
				ii = _virtualItems[curIndex];
				
				if (ii.obj == null || forceUpdate)
				{
					if (itemProvider != null)
					{
						url = itemProvider.runWith(curIndex % _numItems);
						if (url == null)
							url = defaultItem;
					}
					
					if (ii.obj != null && ii.obj.resourceURL != url)
					{
						removeChildToPool(ii.obj);
						ii.obj = null;
					}
				}
				
				if (ii.obj == null)
				{
					if (forward)
					{
						for (j = reuseIndex; j >= oldFirstIndex; j--)
						{
							ii2 = _virtualItems[j];
							if (ii2.obj != null && ii2.updateFlag != itemInfoVer && ii2.obj.resourceURL == url)
							{
								ii.obj = ii2.obj;
								ii2.obj = null;
								if (j == reuseIndex)
									reuseIndex--;
								break;
							}
						}
					}
					else
					{
						for (j = reuseIndex; j <= lastIndex; j++)
						{
							ii2 = _virtualItems[j];
							if (ii2.obj != null && ii2.updateFlag != itemInfoVer && ii2.obj.resourceURL == url)
							{
								ii.obj = ii2.obj;
								ii2.obj = null;
								if (j == reuseIndex)
									reuseIndex++;
								break;
							}
						}
					}
					
					if (ii.obj != null)
					{
						setChildIndex(ii.obj, forward ? curIndex - newFirstIndex : numChildren);
					}
					else
					{
						ii.obj = _pool.getObject(url);
						if (forward)
							this.addChildAt(ii.obj, curIndex - newFirstIndex);
						else
							this.addChild(ii.obj);
					}
					if (ii.obj is GButton)
						GButton(ii.obj).selected = false;
					
					needRender = true;
				}
				else
					needRender = forceUpdate;
				
				if (needRender)
				{
					itemRenderer.runWith([curIndex % _numItems, ii.obj]);
					if (curIndex % _curLineItemCount == 0)
					{
						deltaSize += Math.ceil(ii.obj.width) - ii.width;
						if (curIndex == newFirstIndex && oldFirstIndex > newFirstIndex)
						{
							//当内容向下滚动时，如果新出现的一个项目大小发生变化，需要做一个位置补偿，才不会导致滚动跳动
							firstItemDeltaSize = Math.ceil(ii.obj.width) - ii.width;
						}
					}
					ii.width = Math.ceil(ii.obj.width);
					ii.height = Math.ceil(ii.obj.height);
				}
				
				ii.updateFlag = itemInfoVer;
				ii.obj.setXY(curX, curY);
				if (curIndex == newFirstIndex) //要显示多一条才不会穿帮
					max += ii.width;
				
				curY += ii.height + _lineGap;
				
				if (curIndex % _curLineItemCount == _curLineItemCount - 1)
				{
					curY = 0;
					curX += ii.width + _columnGap;
				}
				curIndex++;
			}
			
			for (i = 0; i < oldCount; i++)
			{
				ii = _virtualItems[oldFirstIndex + i];
				if (ii.updateFlag != itemInfoVer && ii.obj != null)
				{
					removeChildToPool(ii.obj);
					ii.obj = null;
				}
			}
			
			if (deltaSize != 0 || firstItemDeltaSize != 0)
				_scrollPane.changeContentSizeOnScrolling(deltaSize, 0, firstItemDeltaSize, 0);
			
			if (curIndex > 0 && this.numChildren > 0 && _container.x < 0 && getChildAt(0).x > - _container.x)//最后一页没填满！
				handleScroll2(false);
			
			enterCounter--;
		}
		
		private function handleScroll3(forceUpdate:Boolean):void
		{
			var pos:Number = scrollPane.scrollingPosX;
			
			//寻找当前位置的第一条项目
			GList.pos_param = pos;
			var newFirstIndex:int = getIndexOnPos3(forceUpdate);
			pos = GList.pos_param;
			if (newFirstIndex == _firstIndex && !forceUpdate)
				return;
			
			var oldFirstIndex:int = _firstIndex;
			_firstIndex = newFirstIndex;
			
			//分页模式不支持不等高，所以渲染满一页就好了
			
			var reuseIndex:int = oldFirstIndex;
			var virtualItemCount:int = _virtualItems.length;
			var pageSize:int = _curLineItemCount * _curLineItemCount2;
			var startCol:int = newFirstIndex % _curLineItemCount;
			var viewWidth:Number = this.viewWidth;
			var page:int = Math.floor(newFirstIndex / pageSize);
			var startIndex:int = page * pageSize;
			var lastIndex:int = startIndex + pageSize * 2; //测试两页
			var needRender:Boolean;
			var i:int;
			var ii:ItemInfo, ii2:ItemInfo;
			var col:int;
			
			itemInfoVer++;
			
			//先标记这次要用到的项目
			for (i = startIndex; i < lastIndex; i++)
			{
				if (i >= _realNumItems)
					continue;
				
				col = i % _curLineItemCount;
				if (i - startIndex < pageSize)
				{
					if (col < startCol)
						continue;
				}
				else
				{
					if (col > startCol)
						continue;
				}
				
				ii = _virtualItems[i];
				ii.updateFlag = itemInfoVer;
			}
			
			var lastObj:GObject = null;
			var insertIndex:int = 0;
			for (i = startIndex; i < lastIndex; i++)
			{
				if (i >= _realNumItems)
					continue;
				
				col = i % _curLineItemCount;
				if (i - startIndex < pageSize)
				{
					if (col < startCol)
						continue;
				}
				else
				{
					if (col > startCol)
						continue;
				}
				
				ii = _virtualItems[i];
				if (ii.obj == null)
				{
					//寻找看有没有可重用的
					while (reuseIndex < virtualItemCount)
					{
						ii2 = _virtualItems[reuseIndex];
						if (ii2.obj != null && ii2.updateFlag != itemInfoVer)
						{
							ii.obj = ii2.obj;
							ii2.obj = null;
							break;
						}
						reuseIndex++;
					}
					
					if (insertIndex == -1)
						insertIndex = getChildIndex(lastObj) + 1;
					
					if (ii.obj == null)
					{
						ii.obj = _pool.getObject(defaultItem);
						this.addChildAt(ii.obj, insertIndex);
					}
					else
					{
						insertIndex = setChildIndexBefore(ii.obj, insertIndex);
					}
					insertIndex++;
					
					if (ii.obj is GButton)
						GButton(ii.obj).selected = false;
					
					needRender = true;
				}
				else
				{
					needRender = forceUpdate;
					insertIndex = -1;
					lastObj = ii.obj;
				}
				
				if (needRender)
					itemRenderer.runWith([i % _numItems, ii.obj]);
				
				ii.obj.setXY(Math.floor(i / pageSize) * viewWidth + col * (ii.width + _columnGap),
					Math.floor(i / _curLineItemCount) % _curLineItemCount2 * (ii.height + _lineGap));
			}
			
			//释放未使用的
			for (i = reuseIndex; i < virtualItemCount; i++)
			{
				ii = _virtualItems[i];
				if (ii.updateFlag != itemInfoVer && ii.obj != null)
				{
					removeChildToPool(ii.obj);
					ii.obj = null;
				}
			}
		}
		
		private function handleAlign(contentWidth:Number, contentHeight:Number):void
		{
			var newOffsetX:Number = 0;
			var newOffsetY:Number = 0;
			if (_layout == ListLayoutType.SingleColumn || _layout == ListLayoutType.FlowHorizontal || _layout == ListLayoutType.Pagination)
			{
				if (contentHeight < viewHeight)
				{
					if (_verticalAlign == "middle")
						newOffsetY = Math.floor((viewHeight - contentHeight) / 2);
					else if (_verticalAlign == "bottom")
						newOffsetY = viewHeight - contentHeight;
				}
			}
			else
			{
				if (contentWidth < this.viewWidth)
				{
					if (_align == "center")
						newOffsetX = Math.floor((viewWidth - contentWidth) / 2);
					else if (_align == "right")
						newOffsetX = viewWidth - contentWidth;
				}
			}
			
			if (newOffsetX!=_alignOffset.x || newOffsetY!=_alignOffset.y)
			{
				_alignOffset.setTo(newOffsetX, newOffsetY);
				if (scrollPane != null)
					scrollPane.adjustMaskContainer();
				else
				{
					_container.x = _margin.left + _alignOffset.x;
					_container.y = _margin.top + _alignOffset.y;
				}
			}
		}
		
		override protected function updateBounds(): void {
			if(_virtual)
				return;
			
            var i: Number = 0;
            var child: GObject;
            var curX: Number = 0;
            var curY: Number = 0;;
            var maxWidth: Number = 0;
            var maxHeight: Number = 0;
            var cw: Number, ch: Number = 0;
			var sw:int, sh:int;
			var p:int;
			var cnt:int = _children.length;
			var viewWidth:Number = this.viewWidth;
			var viewHeight:Number = this.viewHeight;
			
            for(i = 0;i < cnt;i++) {
                child = this.getChildAt(i);
                child.ensureSizeCorrect();
            }
            
            if (this._layout == ListLayoutType.SingleColumn) {                
                for (i = 0; i < cnt; i++) {
                    child = this.getChildAt(i);
                    if (foldInvisibleItems && !child.visible)
                        continue;

					sw = Math.ceil(child.width);
					sh = Math.ceil(child.height);
					
                    if (curY != 0)
                        curY += this._lineGap;
                    child.y = curY;
                    curY += sh;
                    if (sw > maxWidth)
                        maxWidth = sw;
                }
                cw = curX + maxWidth;
                ch = curY;
            }
            else if (this._layout == ListLayoutType.SingleRow) {                
                for (i = 0; i < cnt; i++) {
                    child = this.getChildAt(i);
                    if (foldInvisibleItems && !child.visible)
                        continue;

					sw = Math.ceil(child.width);
					sh = Math.ceil(child.height);
					
                    if (curX != 0)
                        curX += this._columnGap;
                    child.x = curX;
                    curX += sw;
                    if (sh > maxHeight)
                        maxHeight = sh;
                }
                cw = curX;
                ch = curY + maxHeight;
            }
            else if (this._layout == ListLayoutType.FlowHorizontal) {
                var j: Number = 0;
                for (i = 0; i < cnt; i++) {
                    child = this.getChildAt(i);
                    if (foldInvisibleItems && !child.visible)
                        continue;

					sw = Math.ceil(child.width);
					sh = Math.ceil(child.height);

                    if (curX != 0)
                        curX += this._columnGap;

                    if(this._lineItemCount != 0 && j >= this._lineItemCount
                        || this._lineItemCount == 0 && curX + sw > viewWidth && maxHeight != 0) {
                        //new line
                        curX -= this._columnGap;
                        if(curX > maxWidth)
                            maxWidth = curX;
                        curX = 0;
                        curY += maxHeight + this._lineGap;
                        maxHeight = 0;
                        j = 0;
                    }
                    child.setXY(curX,curY);
                    curX += sw;
                    if(sh > maxHeight)
                        maxHeight = sh;
                    j++;
                }
                ch = curY + maxHeight;
                cw = maxWidth;
            }
			else if (_layout == ListLayoutType.FlowVertical) {
                j = 0;
                for (i = 0; i < cnt; i++) {
                    child = this.getChildAt(i);
                    if (!child.visible)
                        continue;
					
					sw = Math.ceil(child.width);
					sh = Math.ceil(child.height);

                    if (curY != 0)
                        curY += this._lineGap;

                    if(this._lineItemCount != 0 && j >= this._lineItemCount
                        || this._lineItemCount == 0 && curY + sh > viewHeight && maxWidth != 0) {
                        curY -= this._lineGap;
                        if(curY > maxHeight)
                            maxHeight = curY;
                        curY = 0;
                        curX += maxWidth + this._columnGap;
                        maxWidth = 0;
                        j = 0;
                    }
                    child.setXY(curX,curY);
                    curY += sh;
                    if(sw > maxWidth)
                        maxWidth = sw;
                    j++;
                }
                cw = curX + maxWidth;
                ch = maxHeight;
            }
			else //pagination
			{
				for (i = 0; i < cnt; i++)
				{
					child = getChildAt(i);
					if (foldInvisibleItems && !child.visible)
						continue;
					
					sw = Math.ceil(child.width);
					sh = Math.ceil(child.height);
					
					if (curX != 0)
						curX += _columnGap;
					
					if (_lineItemCount != 0 && j >= _lineItemCount
						|| _lineItemCount == 0 && curX + sw > viewWidth && maxHeight != 0)
					{
						//new line
						curX -= _columnGap;
						if (curX > maxWidth)
							maxWidth = curX;
						curX = 0;
						curY += maxHeight + _lineGap;
						maxHeight = 0;
						j = 0;
						
						if (curY + sh > viewHeight && maxWidth != 0)//new page
						{
							p++;
							curY = 0;
						}
					}
					child.setXY(p * viewWidth + curX, curY);
					curX += sw;
					if (sh > maxHeight)
						maxHeight = sh;
					j++;
				}
				ch = curY + maxHeight;
				cw = (p + 1) * viewWidth;
			}
			
			handleAlign(cw, ch);
			
            this.setBounds(0, 0, cw, ch);
        }

        override public function setup_beforeAdd(xml: Object): void {
            super.setup_beforeAdd(xml);

            var str: String;
            var arr: Array;
            
            str = xml.getAttribute("layout");
            if (str)
                this._layout = ListLayoutType.parse(str);

            var overflow: int;
            str = xml.getAttribute("overflow");
            if (str)
                overflow = OverflowType.parse(str);
            else
                overflow = OverflowType.Visible;

            str = xml.getAttribute("margin");
            if(str)
                this._margin.parse(str);
			
			str = xml.getAttribute("align");
			if(str)
				_align = str;
			
			str = xml.getAttribute("vAlign");
			if(str)
				_verticalAlign = str;
			
            if(overflow == OverflowType.Scroll) {
                var scroll: int;
                str = xml.getAttribute("scroll");
                if (str)
                    scroll = ScrollType.parse(str);
                else
                    scroll = ScrollType.Vertical;
    
                var scrollBarDisplay: int;
                str = xml.getAttribute("scrollBar");
                if (str)
                    scrollBarDisplay = ScrollBarDisplayType.parse(str);
                else
                    scrollBarDisplay = ScrollBarDisplayType.Default;
    
                var scrollBarFlags: Number;
                str = xml.getAttribute("scrollBarFlags");
                if(str)
                    scrollBarFlags = parseInt(str);
                else
                    scrollBarFlags = 0;
    
                var scrollBarMargin: Margin = new Margin();
                str = xml.getAttribute("scrollBarMargin");
                if(str)
                     scrollBarMargin.parse(str);
                
                var vtScrollBarRes: String;
                var hzScrollBarRes: String;
                str = xml.getAttribute("scrollBarRes");
                if(str) {
                    arr = str.split(",");
                    vtScrollBarRes = arr[0];
                    hzScrollBarRes = arr[1];
                }
                
                this.setupScroll(scrollBarMargin,scroll,scrollBarDisplay,scrollBarFlags,vtScrollBarRes,hzScrollBarRes);
            }
            else
                this.setupOverflow(overflow);
            
            str = xml.getAttribute("lineGap");
            if (str)
                this._lineGap = parseInt(str);

            str = xml.getAttribute("colGap");
            if (str)
                this._columnGap = parseInt(str);
                
            str = xml.getAttribute("lineItemCount");
            if(str)
                this._lineItemCount = parseInt(str);
                
            str = xml.getAttribute("selectionMode");
            if (str)
                this._selectionMode = ListSelectionMode.parse(str);

            str = xml.getAttribute("defaultItem");
            if (str)
                this._defaultItem = str;
                
            str = xml.getAttribute("autoItemSize");
            this._autoResizeItem = str != "false";

            var col: Array = xml.childNodes;
            var length: int = col.length;
            for (var i: int = 0; i < length; i++) {
                var cxml: Object = col[i];
                if(cxml.nodeName != "item")
                    continue;
                
                var url: String = cxml.getAttribute("url");
                if (!url)
                    url = this._defaultItem;
                if (!url)
                    continue;

                var obj: GObject = this.getFromPool(url);
                if(obj != null) {
                    this.addChild(obj);
					str = cxml.getAttribute("title");
					if(str)
						obj.text = str;
					str = cxml.getAttribute("icon");
					if(str)
						obj.icon = str;
					str = cxml.getAttribute("name");
					if(str)
						obj.name = str;
                }
            }
        }
    }
}

import fairygui.GObject;

class ItemInfo
{
	public var width:Number = 0;
	public var height:Number = 0;
	public var obj:GObject;
	public var updateFlag:uint;
	
	public function ItemInfo():void
	{
	}
}