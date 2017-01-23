package demo.ModalWaitingDemo
{
	import fairygui.GComponent;
	import fairygui.GObject;
	
	import laya.events.Event;
	
	public class GlobalWaiting extends GComponent
	{
		private var _obj: GObject;
		
		public function GlobalWaiting()
		{
			super();
		}
		
		override protected function constructFromXML(xml:Object):void
		{
			super.constructFromXML(xml);
			
			this._obj = this.getChild("n1");
			this.on(Event.DISPLAY,this,this.onAddedToStage);
			this.on(Event.UNDISPLAY,this,this.onRemoveFromStage);        
		}
		
		private function onAddedToStage():void {
			Laya.timer.frameLoop(2, this, this.onTimer);
		}
		
		private function onRemoveFromStage():void {
			Laya.timer.clear(this, this.onTimer);
		}
		
		private function onTimer():void {
			var i:Number = this._obj.rotation;
			i += 10;
			if(i > 360)
				i = i % 360;
			this._obj.rotation = i;
		}
	}
}