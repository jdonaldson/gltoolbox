/*
	@! TODO
	- if context is changed or lost and regained, we need to be careful that textureQuad is still valid
*/

package gltoolbox.render;

import gltoolbox.gl.GL;
import gltoolbox.gl.GLBuffer;
import gltoolbox.gl.GLFramebuffer;
import gltoolbox.gl.GLTexture;
import gltoolbox.render.RenderTools;

class RenderTarget implements IRenderTarget{

	public var width 			 (default, null):Int;
	public var height 			 (default, null):Int;
	public var frameBufferObject (default, null):GLFramebuffer;
	public var texture           (default, null):GLTexture;

	var textureFactory:Int->Int->GLTexture;

	public inline function new(width:Int, height:Int, ?textureFactory:Int->Int->GLTexture){
		if(textureFactory == null){
			textureFactory = gltoolbox.TextureTools.createTextureFactory();
		}

		this.width = width;
		this.height = height;
		this.textureFactory = textureFactory;
		this.texture = textureFactory(width, height);

		this.frameBufferObject = GL.createFramebuffer();

		resize(width, height);
	}

	public inline function resize(width:Int, height:Int):Void{
		var newTexture = textureFactory(width, height);
		//attach texture to frame buffer object's color component	
		GL.bindFramebuffer(GL.FRAMEBUFFER, this.frameBufferObject);
		GL.framebufferTexture2D(GL.FRAMEBUFFER, GL.COLOR_ATTACHMENT0, GL.TEXTURE_2D, newTexture, 0);

		if(this.texture != null){
			var resampler = gltoolbox.shaders.Resample.instance;
			resampler.texture.data = this.texture;

			GL.bindFramebuffer(GL.FRAMEBUFFER, frameBufferObject);
			GL.viewport(0, 0, width, height);

			GL.bindBuffer(GL.ARRAY_BUFFER, RenderTools.textureQuad);

			resampler.activate(true, true);
			GL.drawArrays(GL.TRIANGLE_STRIP, 0, 4);
			resampler.deactivate();

			GL.deleteTexture(this.texture);
		}else clear();

		this.width = width;
		this.height = height;
		this.texture = newTexture;
	
		return this;
	}

	public inline function activate(){
		GL.bindFramebuffer(GL.FRAMEBUFFER, this.frameBufferObject);
	}

	public inline function clear(mask:Int = GL.COLOR_BUFFER_BIT){
		GL.bindFramebuffer(GL.FRAMEBUFFER, this.frameBufferObject);
		GL.clearColor(0, 0, 0, 1);
		GL.clear(mask);
	}

	public inline function dispose(){
		GL.deleteFramebuffer(frameBufferObject);
		GL.deleteTexture(texture);
	}	
}