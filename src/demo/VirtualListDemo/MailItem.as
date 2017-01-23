package demo.VirtualListDemo
{
	import fairygui.Controller;
	import fairygui.GButton;
	import fairygui.GTextField;
	import fairygui.Transition;
	
	public class MailItem extends GButton
	{
		private var _timeText: GTextField;
		private var _readController: Controller;
		private var _fetchController: Controller;
		private var _trans: Transition;
		
		public function MailItem()
		{
			super();
		}
		
		override protected function constructFromXML(xml: Object): void {
			super.constructFromXML(xml);
			
			this._timeText = this.getChild("timeText").asTextField;
			this._readController = this.getController("IsRead");
			this._fetchController = this.getController("c1");
			this._trans = this.getTransition("t0");
		}
		
		public function setTime(value: String): void {
			this._timeText.text = value;
		}
		
		public function setRead(value: Boolean): void {
			this._readController.selectedIndex = value ? 1 : 0;
		}
		
		public function setFetched(value: Boolean): void {
			this._fetchController.selectedIndex = value ? 1 : 0;
		}
		
		public function playEffect(delay: Number): void {
			this.visible = false;
			this._trans.play(null,1,delay);
		}
	}
}