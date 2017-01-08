package 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	/**
	 * ...
	 * @author lenglang
	 */
	public class Main extends Sprite
	{
		private var _sprites:Array = [];//画线数组
		private var _spritePool:Array = [];//对象池
		private var _points:Array = [new Point(100,100),new Point(500,100),new Point(500,500),new Point(100,500)];//纸张初始点
		private var _length:int = 20;//补助折线虚线单根长
		private var _dis:int = 10;//补助折线虚线间距
		private var _clickPoint:Point=new Point();//点击点
		private var _arrow:MovieClip;//补助方向箭头
		private var _movePoint:Point=new Point();//鼠标移动点
		private var _lastPoint:Point=new Point();//上一个点
		private var _symmetryLength:Number = 1000;
		private var _K:Number = 0;//斜率
		private var _b:Number = 0;//b值
		private var _angle:Number = 0;//角度
		private var _firstBoolean:Boolean = false;//离最近的点可对称
		private var _earlyPoint:Point = new Point();
		public function Main()
		{
			if (stage)
			{
				init();
			}
			else
			{
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}

		private function init(e:Event = null):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			//预先创建sprite对象池
			for (var i:int = 0; i < 20; i++)
			{
				var sprite:Sprite = new Sprite();
				addChild(sprite);
				_spritePool.push(sprite);
			}
			//初始纸张
			drawGraphics(_points, 0x000000, 0xffffff);
			//生成箭头
			_arrow = new Arrow();
			_arrow.x = stage.mouseX;
			_arrow.y = stage.mouseY;
			addChild(_arrow);
			//添加事件
			stage.addEventListener(MouseEvent.MOUSE_DOWN, stageMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, stageMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, stageMouseMove);
			this.addEventListener(Event.ENTER_FRAME, this.frameIng);
			stage.mouseChildren = false;
		}
		private function frameIng(e:Event):void
		{

		}
		//移动
		private function stageMouseMove(e:MouseEvent):void
		{
			_arrow.x = stage.mouseX;
			_arrow.y = stage.mouseY;
			_movePoint.x = stage.mouseX;
			_movePoint.y = stage.mouseY;
			if (getAngle(getCenter(_points),_clickPoint) > 0 && getAngle(_movePoint,_clickPoint ) < 0)
			{
				return;
			}
			if (getAngle(getCenter(_points),_clickPoint) <0 && getAngle(_movePoint,_clickPoint) > 0)
			{
				return;
			}
			if (getDistance(_movePoint, _lastPoint) < 10)
			{
				return;
			}
			_lastPoint.x = stage.mouseX;
			_lastPoint.y = stage.mouseY;
			if (e.buttonDown)
			{
				//清空线
				for (var j:int = 0; j < _sprites.length; j++)
				{
					_sprites[j].graphics.clear();
					_spritePool.push(_sprites[j]);
				}
				_sprites = [];
				_angle = getAngle(_clickPoint,_movePoint);
				_arrow.rotation = _angle;
				if (_firstBoolean == false)
				{
					_earlyPoint= getEarlyPoint();
				}
				var radian = (_angle - 90) * Math.PI / 180;
				_K = Math.tan(radian);
				_b = (_earlyPoint.y+_movePoint.y)/2 - (_K * (_movePoint.x+_earlyPoint.x)/2);
				//折线
				var p1:Point = new Point(_symmetryLength,_K * _symmetryLength + _b);
				var p2:Point = new Point( -  _symmetryLength, -  _K * _symmetryLength + _b);
				drawLine(p1, p2, 0x00CC00);
				//是可以映射
				var symmetryPoints:Array = [];
				var lessPoints:Array = [];
				var firstPoint:Point = new Point();
				for (var i:int = _points.length-1; i >=0; i--)
				{
					if (_clickPoint.y < _movePoint.y)
					{
						//下移
						if (_points[i].y > _points[i].x * _K + _b)
				        {
						      lessPoints.push(_points[i]);
					    }
						else
						{
							_firstBoolean = true;
							symmetryPoints.push(getSymmetry(_points[i]));
						}
					}
					else
					{
						//上移
						if (_points[i].y < _points[i].x * _K + _b)
				        {
						      lessPoints.push(_points[i]);
					    }
						else
						{
							_firstBoolean = true;
							symmetryPoints.push(getSymmetry(_points[i]));
						}
					}
				}
				//是否有交点
				var focusPoints:Array = [];
				for (var k:int = 0; k < _points.length; k++)
				{
					var focus:Point;
					if (k == _points.length - 1)
					{
						focus = getFocus(_points[k],_points[0]);
					}
					else
					{
						focus = getFocus(_points[k],_points[k + 1]);
					}
					if (focus != null)
					{
						focusPoints.push(focus);
					}
				}
				var tempPoints:Array = [];
			    tempPoints = tempPoints.concat(lessPoints);
			    tempPoints = tempPoints.concat(focusPoints);;
				focusPoints = focusPoints.concat(symmetryPoints);
				sortPoint(tempPoints);
				sortPoint(focusPoints);
				
			    this.setChildIndex(drawGraphics(tempPoints, 0x000000, 0xffffff),this.numChildren-1);
				this.setChildIndex(drawGraphics(focusPoints, 0xff0000, 0xffffff),this.numChildren-1);
			}
		}
		private function stageMouseDown(e:MouseEvent):void
		{
			_firstBoolean = false;
			_movePoint = new Point(stage.mouseX,stage.mouseY);
			_lastPoint = new Point(stage.mouseX,stage.mouseY);
			_clickPoint = new Point(stage.mouseX,stage.mouseY);
		}
		private function stageMouseUp(e:MouseEvent):void
		{
			//_symmetry.graphics.clear();
		}
		/**
		 * 画图形
		 * @parampoints       点集
		 * @parambgColor      填充颜色
		 * @paramlineColor    线颜色
		 * @paramlineSize     线大小
		 */
		private function drawGraphics(points:Array, bgColor:int, lineColor:int,lineSize:int=2):Sprite
		{
			var sprite:Sprite = getSprite();
			sprite.graphics.lineStyle(lineSize, lineColor);
			sprite.graphics.beginFill(bgColor);
			for (var i:int = 0; i < points.length; i++)
			{
				if (i == 0)
				{
					sprite.graphics.moveTo(points[i].x, points[i].y);
				}
				else
				{
					sprite.graphics.lineTo(points[i].x, points[i].y);
				}
			}
			return sprite;
		}
		/**
		 * 
		 * @paramsp         开始点
		 * @paramep         结束点
		 * @paramlineColor  线颜色
		 * @paramlineSize   线大小
		 */
		private function drawLine(sp:Point, ep:Point, lineColor:int, lineSize:int = 2)
		{
			var sprite:Sprite = getSprite();
			sprite.graphics.lineStyle(lineSize, lineColor);
			sprite.graphics.moveTo(sp.x, sp.y);
			sprite.graphics.lineTo(ep.x, ep.y);
		}
		/**
		 * 获取画线sprite
		 * @return
		 */
		private function getSprite():Sprite
		{
			if (_spritePool.length != 0)
			{
				var temp = _spritePool[0];
				_spritePool.splice(0, 1);
				_sprites.push(temp);
				return temp;
			}
			return null;
		}
		/**
		 * 获取对称点
		 */
		private function getSymmetry(p:Point):Point
		{
			var point:Point=new Point();
			point.x = (2 * p.y * _K - 2 * _b * _K + p.x - _K * _K * p.x) / (1 + _K * _K);
			point.y = p.y - (point.x - p.x) / _K;
			return point;
		}
		/**
		 * 获取两点之间的距离
		 * @paramp1
		 * @paramp2
		 */
		private function getDistance(p1:Point,p2:Point):Number
		{
			return Math.sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
		}
		/**
		 * 获取两点之间角度
		 * @paramp1
		 * @paramp2
		 */
		private function getAngle(p1:Point,p2:Point)
		{
			var vx = p2.x - p1.x;
			var vy = p2.y - p1.y;
			var hyp = Math.sqrt(Math.pow(vx,2) + Math.pow(vy,2));
			var rad=Math.acos(vx/hyp);
			var deg = 180/(Math.PI / rad);
			//得到了一个角度“rad”，不过是以弧度为单位的
			//把它转换成角度 
			if (vy<0)
			{
				deg=(-deg);
			}
			else if ((vy == 0) && (vx <0))
			{
				deg = 180;
			}
			return deg;
		}
		/**
		 * 点排序
		 * @parampoints
		 */
		private function sortPoint(points:Array)
		{
			//重心点
			var center:Point = new Point();
			center = getCenter(points);
			var boolean:Boolean = true;
			while (boolean)
			{
				boolean = false;
				for (var j:int = 0; j < points.length-1; j++)
				{
					if (getAngle(center, points[j]) > getAngle(center, points[j + 1]))
					{
						var temp = points[j];
						points[j] = points[j + 1];
						points[j + 1] = temp;
						boolean = true;
					}
				}
			}
		}
		/**
		 * 获取重心
		 * @return
		 */
		private function getCenter(points:Array):Point
		{
			var center:Point = new Point();
			for (var i:int = 0; i < points.length; i++)
			{
				center.x +=  points[i].x;
				center.y +=  points[i].y;
			}
			center.x = center.x / points.length;
			center.y = center.y / points.length;
			return center;
		}
		/**
		 * 获取折线与线段的交点
		 * @paramp1
		 * @paramp2
		 * @return
		 */
		private function getFocus(p1:Point,p2:Point):Point
		{
			var angle:Number = getAngle(p1,p2);
			var radian = angle * Math.PI / 180;
			var x1:Number;
			var x2:Number;
			var y1:Number;
			var y2:Number;
			var point:Point = new Point();
			var k2 = Math.tan(radian);
			var b2 = p1.y - (k2 * p2.x);
			if (Math.abs(angle) == 90)
			{
				y1 = y2 = _b;
				x1 = x2 = p1.x;
				point.x = x1;
				point.y = _K * x1 + _b;
			}
			else
			{
				x1=x2=point.x = (_b - b2) / (k2 - _K);
				y1 = _K * point.x + _b;
				y2 = k2 * point.x + b2;
				point.y = y1;
			}
			if (Math.round(x1) == Math.round(x2) && Math.round(y1) == Math.round(y2) && Math.round(point.x) >= Math.round(Math.min(p1.x,p2.x)) && Math.round(point.x) <= Math.round(Math.max(p1.x,p2.x)) && Math.round(point.y) <= Math.round(Math.max(p1.y,p2.y)) && Math.round(point.y) >= Math.round(Math.min(p1.y,p2.y)))
			{
				return point;
			}
			return null;
		}
		/**
		 * 与鼠标最近的点
		 */
		private function getEarlyPoint():Point
		{
			trace("判断所有的点");
			var dis:Number = getDistance(new Point(stage.mouseX, stage.mouseY), _points[0]);
			var point:Point = new Point();
			point = _points[0];
			for (var i:int = 1; i < _points.length; i++) 
			{  
				var tempDis:Number = getDistance(new Point(stage.mouseX, stage.mouseY), _points[i]);
				if (dis > tempDis)
				{
					dis = tempDis;
					point = _points[i];
				}
			}
			return point;
		}
	}
}