/**
 * Created by IntelliJ IDEA.
 * User: jesse
 * Date: Sep 26, 2010
 * Time: 2:47:52 PM
 * To change this template use File | Settings | File Templates.
 */
package assets.images
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;

    [Embed(source="/assets/images/next-button-over.png")]
    public class NextButtonOverImage extends Bitmap
    {
        public function NextButtonOverImage(bitmapData:BitmapData=null, pixelSnapping:String="auto", smoothing:Boolean=false)
		{
			super(bitmapData, pixelSnapping, smoothing);
		}
    }
}