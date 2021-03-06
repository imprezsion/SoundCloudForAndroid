package com.jxl.soundcloud.views
{
	import assets.images.Background;
	import assets.images.HeaderImage;
	
	import com.bit101.components.Component;
	import com.greensock.TweenLite;
	import com.greensock.easing.Expo;
	import com.greensock.easing.Strong;
	import com.jxl.soundcloud.Constants;
	import com.jxl.soundcloud.components.DraggableText;
	import com.jxl.soundcloud.components.LinkButton;
	import com.jxl.soundcloud.components.Menu;
	import com.jxl.soundcloud.components.PushButton;
	import com.jxl.soundcloud.components.SongItemRenderer;
	import com.jxl.soundcloud.events.AuthorizeViewEvent;
	import com.jxl.soundcloud.events.LoginEvent;
	import com.jxl.soundcloud.events.MainViewEvent;
	import com.jxl.soundcloud.events.MenuEvent;
	import com.jxl.soundcloud.views.mainviews.ApplicationView;
	import com.jxl.soundcloud.views.mainviews.AuthorizeView;
	import com.jxl.soundcloud.views.mainviews.LoginView;
	
	import flash.desktop.NativeApplication;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageOrientation;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.StageOrientationEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.ui.Keyboard;
	import flash.ui.KeyboardType;

    [Event(name="logout", type="com.jxl.soundcloud.events.LoginEvent")]
    [Event(name="quit", type="com.jxl.soundcloud.events.MainViewEvent")]
	[Event(name="showErrors", type="com.jxl.soundcloud.events.MenuEvent")]
    public class MainView extends Component
	{
		
		public static const STATE_LOGIN:String			= "login_state";
		public static const STATE_AUTHORIZE:String		= "authorize_state";
		public static const STATE_MAIN:String			= "main_state";

		private var background:Background;
		private var header:HeaderImage;
		private var loginView:LoginView;
		private var applicationView:ApplicationView;
		private var authorizeView:AuthorizeView;
		private var soundCloudButton:Sprite;
		private var menu:Menu;
		private var showingMenu:Boolean = false;
		private var changeLogDraggableText:DraggableText;
		
		[Embed(source="change-log.txt", mimeType="application/octet-stream")]
		private var ChangeLog:Class;
		
		private var changeLogText:String;
		
		public function MainView(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0)
		{
			super(parent, xpos, ypos);

		}
		
		protected override function init():void
		{
			super.init();
			
			currentState = STATE_LOGIN;
			setSize(Constants.WIDTH, Constants.HEIGHT);
			
			this.addEventListener(Event.ADDED_TO_STAGE, onAdded);
		}
		
		private function onAdded(event:Event):void
		{
			stage.addEventListener(Event.RESIZE, onResize);
			draw();
			
			if(Capabilities.version.toLowerCase().indexOf("and") != -1)
			{
				NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, onAndroidKeyDown);
			}
			else
			{
				NativeApplication.nativeApplication.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			}
			
			stage.focus = this;
		}
		
		private function onAndroidKeyDown(event:KeyboardEvent):void
		{
			//if(currentState == STATE_MAIN)
			//{
				if(event.keyCode == Keyboard.MENU)
				{
					toggleMenu();
				}
			//}
			
			if(changeLogDraggableText && contains(changeLogDraggableText))
			{
				if(event.keyCode == Keyboard.BACK)
				{
					event.preventDefault();
					changeLogDraggableText.text 	= "";
					changeLogText 					= null;
					removeChild(changeLogDraggableText);
					changeLogDraggableText = null;
					draw();
				}
			}
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			//if(currentState == STATE_MAIN)
			//{
				if(event.keyCode == 220) // "\"
				{
					toggleMenu();
				}
			//}
			
			if(changeLogDraggableText && contains(changeLogDraggableText))
			{
				if(event.keyCode == Keyboard.BACKSPACE)
				{
					event.preventDefault();
					changeLogDraggableText.text 	= "";
					changeLogText 					= null;
					removeChild(changeLogDraggableText);
					changeLogDraggableText = null;
					draw();
				}
			}
			
		}

        protected override function addChildren():void
        {
            super.addChildren();

			background = new Background();
			addChild(background);
			
			header = new HeaderImage();
			addChild(header);
			
			soundCloudButton = new Sprite();
			addChild(soundCloudButton);
			soundCloudButton.mouseChildren = false;
			soundCloudButton.mouseEnabled = true;
			soundCloudButton.buttonMode = soundCloudButton.useHandCursor = true;
			soundCloudButton.addEventListener(MouseEvent.CLICK, onGoToSoundCloud);
        }

		private function onPrematureAdd(event:Event):void
		{
			this.removeEventListener(Event.ADDED_TO_STAGE, onPrematureAdd);
			draw();
		}
		
		private function onResize(event:Event):void
		{
			setSize(stage.stageWidth, stage.stageHeight);
		}
		
        public override function draw():void
        {
			super.draw();

			if(stage == null)
			{
				this.addEventListener(Event.ADDED_TO_STAGE, onPrematureAdd);
				return;
			}
			
            if(loginView)
            {
				loginView.move(0, 0);
				loginView.setSize(width, height - loginView.y);
            }
			
			if(authorizeView)
				authorizeView.setSize(width, height);
			
			
			soundCloudButton.x = 10;
			soundCloudButton.y = 10;
			
			var sg:Graphics = soundCloudButton.graphics;
			sg.clear();
			sg.beginFill(0x00FF00, 0);
			sg.drawRect(0, 0, 77, 47);
			sg.endFill();
            
			if(applicationView)
			{
				applicationView.move(0, soundCloudButton.y + soundCloudButton.height);
				applicationView.setSize(width, height - applicationView.y);
			}
			
		
			if(header)
			{
				if(currentState == STATE_AUTHORIZE)
				{
					header.visible = false;
				}
				else
				{
					header.visible = true;
				}
			}
			
			setChildIndex(soundCloudButton, numChildren - 1);
			setChildIndex(background, 0);
			if(menu)
			{
				setChildIndex(menu, numChildren - 1);
				if(showingMenu && authorizeView)
				{
					authorizeView.setSize(width, height - menu.height);
				}
			}
			
			if(changeLogDraggableText)
			{
				changeLogDraggableText.move(0, soundCloudButton.y + soundCloudButton.height);
				changeLogDraggableText.setSize(width, height - changeLogDraggableText.y);
				if(authorizeView)
					authorizeView.hide();
			}
			else
			{
				if(authorizeView)
					authorizeView.show();
			}
        }
		
		protected override function onEnterState(state:String):void
		{
			try
			{
				switch(state)
				{
					case STATE_LOGIN:
						if(loginView == null)
						{
							loginView = new LoginView();
							loginView.addEventListener(LoginEvent.LOGIN, onLogin);
						}
						addChild(loginView);
	                    invalidateDraw();
						break;
					
					case STATE_AUTHORIZE:
						if(authorizeView == null)
						{
							authorizeView = new AuthorizeView();
						}
						addChild(authorizeView);
						break;
					
					case STATE_MAIN:
						if(applicationView == null)
						{
							applicationView = new ApplicationView();
						}
						addChild(applicationView);
						stage.focus = this;
						break;
				}
				draw();
			}
			catch(err:Error)
			{
				Debug.log("MainView::onEnterState '" + state + "' error: " + err);
			}
		}
		
		protected override function onExitState(oldState:String):void
		{
			switch(oldState)
			{
				case STATE_LOGIN:
					if(loginView)
					{
						removeChild(loginView);
					}
					break;
				
				case STATE_AUTHORIZE:
					if(authorizeView)
					{
						removeChild(authorizeView);
                        authorizeView.destroy();
                        authorizeView = null;
					}
					break;
				
				case STATE_MAIN:
					if(contains(applicationView))
						removeChild(applicationView);
					break;
				
			}
		}

		private function toggleMenu():void
		{
			if(menu == null)
			{
				menu = new Menu();
				addChild(menu);
				menu.addEventListener(MenuEvent.CHANGE_LOG, onChangeLog);
				menu.addEventListener(MenuEvent.DISCONNECT, onDisconnect);
				menu.addEventListener(MenuEvent.QUIT, onQuit);
				menu.addEventListener(MenuEvent.REFRESH, onRefresh);
				menu.addEventListener(MenuEvent.SHOW_ERRORS, onShowErrors);
			}
			
			if(showingMenu == false)
			{
				showingMenu = true;
				menu.y = height + 1;
				menu.alpha = 0;
				TweenLite.to(menu, .5, {y: height - menu.height, ease: Expo.easeOut});
				TweenLite.to(menu, .5, {alpha: 1, overwrite: false});
			}
			else
			{
				showingMenu = false;
				menu.y = height - menu.height;
				TweenLite.to(menu, .5, {y: height + 1, ease: Expo.easeOut});
				TweenLite.to(menu, .5, {alpha: 0, overwrite: false});
			}
			
			draw();
			
		}
		
		private function onChangeLog(event:MenuEvent):void
		{
			if(showingMenu) toggleMenu();
			dispatchEvent(event);
			if(changeLogDraggableText == null)
			{
				changeLogDraggableText = new DraggableText();
			}
			
			if(contains(changeLogDraggableText) == false)
				addChild(changeLogDraggableText);
			
			if(changeLogText == null)
				changeLogText = new ChangeLog();
			
			changeLogDraggableText.text = changeLogText;
			draw();
		}
		
		private function onRefresh(event:MenuEvent):void
		{
			if(showingMenu) toggleMenu();
			if(authorizeView == null)
			{
				dispatchEvent(event);
			}
			else
			{
				authorizeView.refresh();
			}
		}
		
		private function onShowErrors(event:MenuEvent):void
		{
			if(showingMenu) toggleMenu();
			dispatchEvent(event);
		}
		
		private function onLogin(event:LoginEvent):void
		{
			currentState = STATE_AUTHORIZE;
		}
		
        private function onDisconnect(event:MenuEvent):void
        {
			if(showingMenu) toggleMenu();
            dispatchEvent(new LoginEvent(LoginEvent.LOGOUT));
        }

        private function onQuit(event:MenuEvent):void
        {
			if(showingMenu) toggleMenu();
            dispatchEvent(new MainViewEvent(MainViewEvent.QUIT));
        }
		
		private function onGoToSoundCloud(event:MouseEvent):void
		{
			try
			{
				navigateToURL(new URLRequest("http://soundcloud.com"));
			}
			catch(err:Error)
			{
				Debug.log("MainView::onGoToSoundCloud, error: " + err);
			}
		}
	}
}