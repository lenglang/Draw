package 
{
	import flash.display.Graphics;
	import flash.geom.Point;
	/**
	 * ...
	 * @author lenglang
	 */
	public class DottedLine 
	{
		
		public function DottedLine() 
		{
			
		}
		/**         * 画虚线
         * 
         * @param    graphics    <b>    Graphics</b> 
         * @param    beginPoint    <b>    Point    </b> 起始点坐标
         * @param    endPoint    <b>    Point    </b> 终点坐标
         * @param    width        <b>    Number    </b> 虚线的长度
         * @param    grap        <b>    Number    </b> 虚线短线之间的间隔
         */
		public static function drawDashed(graphics:Graphics, beginPoint:Point, endPoint:Point, width:Number, grap:Number):void
        {
            if (!graphics || !beginPoint || !endPoint || width <= 0 || grap <= 0) return;
            
            var Ox:Number = beginPoint.x;
            var Oy:Number = beginPoint.y;
            
            var radian:Number = Math.atan2(endPoint.y - Oy, endPoint.x - Ox);
            var totalLen:Number = Point.distance(beginPoint, endPoint);
            var currLen:Number = 0;
            var x:Number, y:Number;
            
            while (currLen <= totalLen)
            {
                x = Ox + Math.cos(radian) * currLen;
                y = Oy +Math.sin(radian) * currLen;
                graphics.moveTo(x, y);
                
                currLen += width;
                if (currLen > totalLen) currLen = totalLen;
                
                x = Ox + Math.cos(radian) * currLen;
                y = Oy +Math.sin(radian) * currLen;
                graphics.lineTo(x, y);
                
                currLen += grap;
            }
            
        }
	}

}