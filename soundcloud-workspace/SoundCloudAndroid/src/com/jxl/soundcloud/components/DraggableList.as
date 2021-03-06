package com.jxl.soundcloud.components
{
	import com.bit101.components.Component;
	import com.jxl.soundcloud.components.IItemRenderer;
	
	import flash.debugger.enterDebugger;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	public class DraggableList extends Component
	{
		private var listContent:Sprite;
		
		
		private var _items:Array;
		private var itemsDirty:Boolean = false;
		private var _itemRenderer:Class;
		private var itemRendererDirty:Boolean = false;
		private var oldWidth:Number;
		private var oldHeight:Number;
		private var rendererPool:Array = [];
		
		
		//------ Scrolling ---------------
		
		private var lastY:Number = 0; // last touch position
		private var firstY:Number = 0; // first touch position
		private var listY:Number = 0; // initial list position on touch 
		private var diffY:Number = 0;
		private var inertiaY:Number = 0;
		private var minY:Number = 0;
		private var maxY:Number = 0;
		private var totalY:Number;
		private var scrollRatio:Number = 40; // how many pixels constitutes a touch
		
		
		private var listWidth:Number;
		private var listHeight:Number;
		private var isTouching:Boolean = false;
		private var scrollListHeight:Number;
		private var scrollAreaHeight:Number;
		private var listTicker:Sprite;
		
		private var scrollBar:Shape;
		
		
		public function get items():Array { return _items; }
		public function set items(value:Array):void
		{
			_items = value;
			itemsDirty = true;
			invalidateProperties();
		}
		
		public function get itemRenderer():Class { return _itemRenderer; }
		public function set itemRenderer(value:Class):void
		{
			_itemRenderer = value;
			itemRendererDirty = true;
			invalidateProperties();
		}
		
		public function DraggableList(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0)
		{
			super(parent, xpos, ypos);
		}
		
		protected override function init():void
		{
			setSize(480, 800);
			
			listWidth = 480;
			listHeight = 800;
			
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown );
			
			//listTimer = new Timer( 33 );
			//listTimer.addEventListener( TimerEvent.TIMER, onListTimer);
			//listTimer.start();
			
			listTicker = new Sprite();
			listTicker.addEventListener(Event.ENTER_FRAME, onListTicker);
			
			super.init();
		}
		
		protected override function addChildren():void
		{
			super.addChildren();
			
			listContent = new Sprite();
			addChild(listContent);
			listContent.mouseChildren = true;
			listContent.mouseEnabled = true;
			//listContent.cacheAsBitmap = true;
			//listContent.cacheAsBitmapMatrix = new Matrix();
			updateScrollBar();
		}
		
		
		protected override function commitProperties():void
		{
			super.commitProperties();
			
			if(itemsDirty || itemRendererDirty)
			{
				itemsDirty = false;
				itemRendererDirty = false;
				redrawListItems();
				draw();
			}
		}
		
		public override function draw():void
		{
			super.draw();
			
			const MARGIN:Number = 4;
			
			if(oldWidth != width || oldHeight != height)
			{
				oldWidth = width;
				oldHeight = height;
				if(_items && _items.length > 0 && listContent && listContent.numChildren > 0)
				{
					resizeChildren();
				}
			}
		}
		
		private function redrawListItems():void
		{
			oldWidth 	= width;
			oldHeight 	= height;
			
			listWidth 	= width;
			listHeight 	= height;
			
			if(listContent)
				removeChildren(listContent)
			
			
			if(_items == null) return;
			if(_items.length < 1) return;
			
			//listContent.cacheAsBitmap = false;
			
			const len:int 		= _items.length;
			var startY:Number 	= 0;
			const MARGIN:Number = 20;
			for(var index:int = 0; index < len; index++)
			{
				try
				{
					var renderer:IItemRenderer = getItem();
				}
				catch(err:Error)
				{
					Debug.log("List::redrawListItems, failure to create renderer instantiation.");
					flash.debugger.enterDebugger();
					return;
				}
				if(renderer == null)
				{
					Debug.log("List::redrawListItems, failure to create renderer, probably doesn't implement IItemRenderer");
					return;
				}
				renderer.data 	= _items[index];
				renderer.y 		= startY;
				renderer.width 	= width;
				startY 			+= renderer.height + MARGIN;
				listContent.addChild(DisplayObject(renderer));
			}
			
			var listGraphics:Graphics = listContent.graphics;
			listGraphics.clear();
			listGraphics.beginFill(0xFFFFFF, 0);
			listGraphics.drawRect(0, 0, width, startY);
			listGraphics.endFill();
			
			//listContent.cacheAsBitmap = true;
			
			scrollRect 			= new Rectangle(0, 0, width, height);
			scrollListHeight 	= startY;
			scrollAreaHeight 	= listHeight;
			
			updateScrollBar();
		}
		
		private function resizeChildren():void
		{
			//listContent.cacheAsBitmap = false;
			
			const len:int = _items.length;
			var startY:Number = 0;
			const MARGIN:Number = 20;
			for(var index:int = 0; index < len; index++)
			{
				var renderer:IItemRenderer 	= listContent.getChildAt(index) as IItemRenderer;
				renderer.y 					= startY;
				renderer.width 				= width;
				startY 						+= renderer.height + MARGIN;
			}
			
			var listGraphics:Graphics = listContent.graphics;
			listGraphics.clear();
			listGraphics.beginFill(0xFFFFFF, 0);
			listGraphics.drawRect(0, 0, width, startY);
			listGraphics.endFill();
			
			//listContent.cacheAsBitmap = true;
			
			scrollRect = new Rectangle(0, 0, width, height);
			
			updateScrollBar();
		}
		
		private function getItem():IItemRenderer
		{
			if(this.rendererPool.length > 0)
			{
				return rendererPool.shift();
			}
			else
			{
				return new _itemRenderer() as IItemRenderer;
			}
		}
		
		private function removeChildren(container:DisplayObjectContainer):void
		{
			var i:int = container.numChildren;
			while(i--)
			{
				var item:DisplayObject = container.removeChildAt(i);
				rendererPool.push(item);
			}
		}
		
		
		private function updateScrollBar():void
		{
			if(scrollBar == null)
			{
				scrollBar = new Shape();
				addChild(scrollBar);
				scrollBar.cacheAsBitmap = true;
			}
			scrollBar.x = listWidth - 5;
			scrollBar.graphics.clear();
			
			if(scrollAreaHeight < scrollListHeight)
			{
				scrollBar.graphics.beginFill(0x505050);
				//scrollBar.graphics.beginFill(0xFF0000, .8);
				scrollBar.graphics.lineStyle(1, 0x5C5C5C, 1, true);
				//scrollBar.graphics.lineStyle(1, 0xFF0000, .8);
				scrollBar.graphics.drawRoundRect(0, 0, 4, (scrollAreaHeight/scrollListHeight*scrollAreaHeight), 6, 6);
				scrollBar.graphics.endFill();
				//scrollBar.alpha = 0;
			}
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp, false, 0, true);
			this.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			this.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			inertiaY 	= 0;
			firstY 		= mouseY;
			listY 		= listContent.y;
			minY 		= Math.min(-listContent.y, -scrollListHeight + listHeight - listContent.y);
			maxY 		= -listContent.y;
			
		}
		
		private function onMouseMove(event:MouseEvent):void
		{
			totalY = mouseY - firstY;
			
			if(Math.abs(totalY) > scrollRatio) isTouching = true;
			
			if(isTouching)
			{
				
				diffY = mouseY - lastY;	
				lastY = mouseY;
				
				if(totalY < minY)
					totalY = minY - Math.sqrt(minY - totalY);
				
				if(totalY > maxY)
					totalY = maxY + Math.sqrt(totalY - maxY);
				
				listContent.y = listY + totalY;
				
				//onTapDisabled();
			}
			
			event.updateAfterEvent();
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown );
			stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove );
			removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			if(isTouching) {
				isTouching = false;
				inertiaY = diffY;
			}
		}
		
		
		
		/**
		 * Timer event handler.  This is always running keeping track
		 * of the mouse movements and updating any scrolling or
		 * detecting any tap events.
		 * 
		 * Mouse x,y coords come through as negative integers when this out-of-window tracking happens. 
		 * The numbers usually appear as -107374182, -107374182. To avoid having this problem we can 
		 * test for the mouse maximum coordinates.
		 * */
		//private function onListTimer(e:TimerEvent):void
		private function onListTicker(e:Event):void
		{
			// scroll the list on mouse up
			if(!isTouching) {
				
				if(listContent.y > 0) {
					inertiaY = 0;
					listContent.y *= 0.3;
					
					if(listContent.y < 1) {
						listContent.y = 0;
					}
				} else if(scrollListHeight >= listHeight && listContent.y < listHeight - scrollListHeight) {
					inertiaY = 0;
					
					var diff:Number = (listHeight - scrollListHeight) - listContent.y;
					
					if(diff > 1)
						diff *= 0.1;
					
					listContent.y += diff;
				} else if(scrollListHeight < listHeight && listContent.y < 0) {
					inertiaY = 0;
					listContent.y *= 0.8;
					
					if(listContent.y > -1) {
						listContent.y = 0;
					}
				}
				
				if( Math.abs(inertiaY) > 1) {
					listContent.y += inertiaY;
					inertiaY *= 0.9;
				} else {
					inertiaY = 0;
				}
				
				if(inertiaY != 0) {
					//if(scrollBar.alpha < 1 )
						//scrollBar.alpha = Math.min(1, scrollBar.alpha + 0.1);
					scrollBar.y = listHeight * Math.min( 1, (-listContent.y/scrollListHeight) );
				} else {
					//if(scrollBar.alpha > 0 )
						//scrollBar.alpha = Math.max(0, scrollBar.alpha - 0.1);
				}
				
				if(inertiaY == 0)
				{
					scrollBar.visible = false
				}
				else
				{
					scrollBar.visible = true;
				}
				
				
			} else {
				//if(scrollBar.alpha < 1)
					//scrollBar.alpha = Math.min(1, scrollBar.alpha + 0.1);
				
				scrollBar.y = listHeight * Math.min(1, (-listContent.y/scrollListHeight) );
				scrollBar.visible = true;
			}
			
			
		}
	}
}