/** 
 * @file stk11xx-dev-0408.c
 * @author Ivor Hewitt
 * @date 2009-01-01
 * @version v1.0.x
 *
 * @brief Driver for Syntek USB video camera
 *
 * @note Copyright (C) Nicolas VIVIEN
 *       Copyright (C) Ivor Hewitt
 *
 * @par Licences
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 * @par SubVersion
 *   $Date$
 *   $Revision$
 *   $Author$
 *   $HeadURL$
 */

/*
 * note currently only supporting 720x576, 704x576 and 640x480 PAL
 * other resolutions should work but aren't
 */

#import "ECVSTK1160Controller.h"
#import <unistd.h>

// STK1160
#import "stk11xx.h"

// SAA7115 datasheet: http://www.datasheetarchive.com/pdf-datasheets/Datasheets-26/DSA-502343.pdf

enum {
	SAA7115MODECompositeAI11 = 0,
	SAA7115MODECompositeAI12 = 1,
	SAA7115MODECompositeAI21 = 2,
	SAA7115MODECompositeAI22 = 3,
	SAA7115MODECompositeAI23 = 4,
	SAA7115MODECompositeAI24 = 5,
	SAA7115MODESVideoAI11_GAI2 = 6,
	SAA7115MODESVideoAI12_GAI2 = 7,
	SAA7115MODESVideoAI11_YGain = 8,
	SAA7115MODESVideoAI12_YGain = 9,
	SAA7115FUSE0Antialias = 1 << 6,
	SAA7115FUSE1Amplifier = 1 << 7
};
enum {
	SAA7115YCOMBAdaptiveLuminanceComb = 1 << 6,
	SAA7115BYPSChrominanceTrapCombBypass = 1 << 7,
};
static u_int8_t SAA7115ModeForVideoSource(ECVSTK1160VideoSource s)
{
	switch(s) {
		case ECVSTK1160SVideoInput: return SAA7115MODESVideoAI12_YGain;
		case ECVSTK1160Composite1Input: return SAA7115MODECompositeAI11;
		case ECVSTK1160Composite2Input: return SAA7115MODECompositeAI21; // The rest are guesses.
		case ECVSTK1160Composite3Input: return SAA7115MODECompositeAI23;
		case ECVSTK1160Composite4Input: return SAA7115MODECompositeAI24;
		default: return 0;
	}
}

/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief This function initializes the device.
 *
 * This function must be called at first. It's the start of the
 * initialization process. After this process, the device is
 * completly initalized and it's ready.
 *
 * This function is written from the USB log.
 */
int dev_stk0408_initialize_device(ECVSTK1160Controller *dev)
{
	int i;
	int retok;
	int value;

	STK_INFO("Initialize USB2.0 Syntek Capture device\n");

//what is all this writing to register 2 doing?
	usb_stk11xx_write_registry(dev, 0x0002, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0000, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0002, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0003, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0002, 0x0007);

	usb_stk11xx_read_registry(dev, 0x0002, &value);
	usb_stk11xx_read_registry(dev, 0x0000, &value);

	dev_stk0408_write0(dev, 7, 4);
	dev_stk0408_write0(dev, 7, 4);
	dev_stk0408_write0(dev, 7, 6);
	dev_stk0408_write0(dev, 7, 7);
	dev_stk0408_write0(dev, 7, 6);
	dev_stk0408_write0(dev, 7, 4);
	dev_stk0408_write0(dev, 7, 5);

	for (i=0;i<7;i++)
	{
		dev_stk0408_write0(dev, 7, 4);
		dev_stk0408_write0(dev, 7, 4);
		dev_stk0408_write0(dev, 7, 5);
	}

/* start set */
	usb_stk11xx_write_registry(dev, 0x0002, 0x0007);
	usb_stk11xx_write_registry(dev, 0x0000, 0x0001);
	
	dev_stk0408_configure_device(dev,1);
	dev_stk0408_configure_device(dev,2);
	
	usb_stk11xx_write_registry(dev, 0x0500, 0x0094); 
	msleep(10);
	
	dev_stk0408_camera_asleep(dev);

	usb_stk11xx_write_registry(dev, 0x0002, 0x0078);
	usb_stk11xx_write_registry(dev, 0x0000, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0203, 0x00a0);
	usb_stk11xx_read_registry(dev, 0x0003, &value);
	usb_stk11xx_write_registry(dev, 0x0003, 0x0000);

	usb_stk11xx_read_registry(dev, 0x0002, &value); //78?
	usb_stk11xx_write_registry(dev, 0x0002, 0x007f);

	usb_stk11xx_read_registry(dev, 0x0002, &value); //7f?
	usb_stk11xx_read_registry(dev, 0x0000, &value); //0?

	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x006);
	dev_stk0408_write0(dev, 0x07f, 0x007);
	dev_stk0408_write0(dev, 0x07f, 0x006);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x005);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x005);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x006);
	dev_stk0408_write0(dev, 0x07f, 0x007);
	dev_stk0408_write0(dev, 0x07f, 0x006);
	dev_stk0408_write0(dev, 0x07f, 0x006);
	dev_stk0408_write0(dev, 0x07f, 0x007);
	dev_stk0408_write0(dev, 0x07f, 0x006);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x005);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x005);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x005);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x004);
	dev_stk0408_write0(dev, 0x07f, 0x005);

	usb_stk11xx_write_registry(dev, 0x0002, 0x007f);
	usb_stk11xx_write_registry(dev, 0x0000, 0x0001);

	retok = dev_stk11xx_check_device(dev, 500);

	usb_stk11xx_set_feature(dev, 1); 

	// Device is initialized and is ready !!!
	STK_INFO("Syntek USB2.0 Capture device is ready\n");

	return 0;
}

int dev_stk0408_write0(ECVSTK1160Controller *dev, int mask, int val)
{
	int value;

	usb_stk11xx_write_registry(dev, 0x0002, mask);
	usb_stk11xx_write_registry(dev, 0x0000, val);
	usb_stk11xx_read_registry(dev, 0x0002, &value);
	usb_stk11xx_read_registry(dev, 0x0000, &value);

	return 0;
}

int dev_stk0408_write_208(ECVSTK1160Controller *dev, int val)
{
	int value;
	int retok;
	
	usb_stk11xx_read_registry(dev, 0x02ff, &value);
	usb_stk11xx_write_registry(dev, 0x02ff, 0x0000);

	usb_stk11xx_write_registry(dev, 0x0208, val);
	usb_stk11xx_write_registry(dev, 0x0200, 0x0020);

	retok = dev_stk0408_check_device(dev);

	if (retok != 1) {
		return -1;
	}

	usb_stk11xx_read_registry(dev, 0x0209, &value);
	usb_stk11xx_write_registry(dev, 0x02ff, 0x0000);

	dev_stk0408_write_saa(dev, val, value);

	return 1;
}

int dev_stk0408_write_saa(ECVSTK1160Controller *dev, int reg, int val)
{
	int value;
	int retok;
	
	usb_stk11xx_read_registry(dev, 0x02ff, &value);
	usb_stk11xx_write_registry(dev, 0x02ff, 0x0000);

	usb_stk11xx_write_registry(dev, 0x0204, reg);
	usb_stk11xx_write_registry(dev, 0x0205, val);
	usb_stk11xx_write_registry(dev, 0x0200, 0x0001);

	retok = dev_stk0408_check_device(dev);

	if (retok != 1) {
		return -1;
	}

	usb_stk11xx_write_registry(dev, 0x02ff, 0x0000);

	return 1;
}

int dev_stk0408_set_resolution(ECVSTK1160Controller *dev)
{
/*
 * These registers control the resolution of the capture buffer.
 * 
 * xres = (X - xsub) / 2
 * yres = (Y - ysub)
 *
 */
	int x,y,xsub,ysub;
	
	switch (stk11xx_image_sizes[dev->resolution].x)
	{
		case 720:
			x = 0x5a0;
			xsub = 0;
			break;
			
		case 704:
		case 352:
		case 176:
			x = 0x584;
			xsub = 4;
			break;

		case 640:
		case 320:
		case 160:
			x = 0x508;
			xsub = 0x08;
			break;

		default:
			return -1;
	}

	switch (stk11xx_image_sizes[dev->resolution].y)
	{
		case 576:
		case 288:
		case 144:
			y = 0x121;
			ysub = 0x1;
			break;

		case 480:
			y = dev.isNTSCFormat ? 0xf3 : 0x110; // Not sure these are tied to NTSC, but 0xf3 and 0x03 are the values I get.
			ysub= dev.isNTSCFormat ? 0x03 : 0x20;
			break;
		
		case 120:
		case 240:	
			y = 0x103;
			ysub = 0x13;
			break;

		default:
			return -1;
	}

	usb_stk11xx_write_registry(dev, 0x0110, xsub ); // xsub
	usb_stk11xx_write_registry(dev, 0x0111, 0    );
	usb_stk11xx_write_registry(dev, 0x0112, ysub ); // ysub
	usb_stk11xx_write_registry(dev, 0x0113, 0    );
	usb_stk11xx_write_registry(dev, 0x0114, x    ); // X
	usb_stk11xx_write_registry(dev, 0x0115, 5    );
	usb_stk11xx_write_registry(dev, 0x0116, y    ); // Y
	usb_stk11xx_write_registry(dev, 0x0117, dev.isNTSCFormat ? 0 : 1); // Not sure this is tied to NTSC either, but I get 0 and 1 doesn't work.
	
	return 0;
}


/** 
 * @param dev Device structure
 * @param step The step of configuration [0-6]
 * 
 * @returns 0 if all is OK
 *
 * @brief This function configures the device.
 *
 * This is called multiple times through intitialisation and configuration
 * there appear to be six distinct steps
 *
 */
int dev_stk0408_configure_device(ECVSTK1160Controller *dev, int step)
{
	int value;
	int asize;
	int i;
	

	const const int ids[] = {
		0x203,0x00d,0x00f,0x103,0x018,0x01b,0x01c,0x01a,0x019,
		0x300,0x350,0x351,0x352,0x353,0x300,0x018,0x202,
		0x110,
		0x111,
		0x112,
		0x113,
		0x114,
		0x115,
		0x116,
		0x117
	};
	
	int const values[] = {
		0x04a,0x000,0x002,0x000,0x000,0x00e,0x046,0x014,0x000,
		0x012,0x02d,0x001,0x000,0x000,0x080,0x010,0x00f,
		(dev.isNTSCFormat ? 0x038 : 0x008),
		0x000,
		(dev.isNTSCFormat ? 0x003 : 0x013),
		0x000,
		(dev.isNTSCFormat ? 0x038 : 0x008),
		0x005,
		(dev.isNTSCFormat ? 0x0f3 : 0x003),
		(dev.isNTSCFormat ? 0x000 : 0x001)
	};

	if (step != 1)
	{
		usb_stk11xx_read_registry(dev, 0x0003, &value);
		usb_stk11xx_read_registry(dev, 0x0001, &value);
		usb_stk11xx_read_registry(dev, 0x0002, &value);
		usb_stk11xx_read_registry(dev, 0x0000, &value);
		usb_stk11xx_read_registry(dev, 0x0003, &value);
		usb_stk11xx_read_registry(dev, 0x0001, &value);
		usb_stk11xx_write_registry(dev, 0x0002, 0x0078);
		usb_stk11xx_write_registry(dev, 0x0000, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0003, 0x0080);
		usb_stk11xx_write_registry(dev, 0x0001, 0x0003);

		usb_stk11xx_read_registry(dev, 0x0002, &value);
		usb_stk11xx_read_registry(dev, 0x0000, &value);
		usb_stk11xx_write_registry(dev, 0x0002, 0x0078);
		usb_stk11xx_read_registry(dev, 0x0000, &value);
		usb_stk11xx_read_registry(dev, 0x0002, &value);
		usb_stk11xx_read_registry(dev, 0x0000, &value);
		usb_stk11xx_write_registry(dev, 0x0002, 0x0078);
		usb_stk11xx_write_registry(dev, 0x0000, 0x0030);
		usb_stk11xx_read_registry(dev, 0x0002, &value);
		usb_stk11xx_read_registry(dev, 0x0002, &value);
		usb_stk11xx_write_registry(dev, 0x0002, 0x0078);
	}
	
	asize = ARRAY_SIZE(values);
	
	for(i=0; i<asize; i++) {
		usb_stk11xx_write_registry(dev, ids[i], values[i]);
	}

	if (step == 1)
	{
		usb_stk11xx_read_registry(dev, 0x0100, &value);
		usb_stk11xx_write_registry(dev, 0x0100, 0x0000);
	}
	else
	{
		usb_stk11xx_read_registry(dev, 0x0100, &value);
		usb_stk11xx_write_registry(dev, 0x0100, 0x0033);
	}

	if (step <=2 )
	{
		return 0;
	}
	
	if (step==3)
	{
		dev_stk0408_sensor_settings(dev);
	}

	usb_stk11xx_read_registry(dev, 0x0100, &value);
	usb_stk11xx_write_registry(dev, 0x0100, 0x0033);
	usb_stk11xx_write_registry(dev, 0x0103, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0100, 0x0033);

	
	switch (step)
	{		
		case 3: /* all fine */
			usb_stk11xx_write_registry(dev, 0x0104, 0x0000);
			usb_stk11xx_write_registry(dev, 0x0105, 0x0000);
			usb_stk11xx_write_registry(dev, 0x0106, 0x0000);

			dev_stk11xx_camera_off(dev);

			usb_stk11xx_write_registry(dev, 0x0500, 0x0094);
			usb_stk11xx_write_registry(dev, 0x0500, 0x008c);
			usb_stk11xx_write_registry(dev, 0x0506, 0x0001);
			usb_stk11xx_write_registry(dev, 0x0507, 0x0000);

			break;
			
		case 5:
/*			if ((dev->resolution == STK11XX_320x240)||
				(dev->resolution == STK11XX_352x288))
			{
				usb_stk11xx_write_registry(dev, 0x0104, 0x0000);
				usb_stk11xx_write_registry(dev, 0x0105, 0x0000);
				} */
		
			usb_stk11xx_write_registry(dev, 0x0106, 0x0000);

			dev_stk0408_set_camera_input(dev);

			break;
	}

	if (step == 3)
	{
		dev_stk0408_set_camera_input(dev);

		//test and set?
		usb_stk11xx_write_registry(dev, 0x0504, 0x0012);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x0012);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0080);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);
			
		usb_stk11xx_write_registry(dev, 0x0504, 0x0010);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x0010);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);
			
		usb_stk11xx_write_registry(dev, 0x0504, 0x000e);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x000e);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);
			
		usb_stk11xx_write_registry(dev, 0x0504, 0x0016);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x0016);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);

		usb_stk11xx_write_registry(dev, 0x0504, 0x001a);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0004);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0004);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);

		usb_stk11xx_write_registry(dev, 0x0504, 0x0002);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x0002);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0080);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);
	
		usb_stk11xx_write_registry(dev, 0x0504, 0x001c);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x001c);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0080);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);		

		dev_stk0408_set_camera_input(dev);

	}

	if ((step == 4 )|| (step == 6))
	{
		dev_stk0408_set_camera_input(dev);
		dev_stk0408_write_208(dev,0x0e);

		dev_stk0408_set_resolution(dev);

		usb_stk11xx_write_registry(dev, 0x0002, 0x0078);
		dev_stk0408_set_camera_quality(dev);
	}

	if (step == 6)
	{
		usb_stk11xx_write_registry(dev, 0x0002, 0x0078);

		dev_stk0408_write_208(dev,0x0e);

		dev_stk0408_set_resolution(dev);

		usb_stk11xx_write_registry(dev, 0x0002, 0x0078);

		dev_stk0408_select_input(dev, dev->vsettings.input);

		dev_stk0408_start_stream(dev);

		usb_stk11xx_write_registry(dev, 0x0504, 0x0002);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x0002);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0080);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);
	
		usb_stk11xx_write_registry(dev, 0x0504, 0x001c);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x001c);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0080);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);		

		usb_stk11xx_write_registry(dev, 0x0504, 0x0002);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x0002);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);
	
		usb_stk11xx_write_registry(dev, 0x0504, 0x001c);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008b);
		usb_stk11xx_write_registry(dev, 0x0504, 0x001c);
		usb_stk11xx_write_registry(dev, 0x0502, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0503, 0x0000);
		usb_stk11xx_write_registry(dev, 0x0500, 0x008c);

		dev_stk0408_start_stream(dev);

	}

	if (step==4)
	{	
		dev_stk11xx_camera_on(dev);
	}
	
	return 0;
}


int dev_stk0408_select_input(ECVSTK1160Controller *dev, int input)
{
	switch (input)
	{
		case 1:
			usb_stk11xx_write_registry(dev, 0x0000, 0x0098);
			break;
		case 2:
			usb_stk11xx_write_registry(dev, 0x0000, 0x0090);
			break;
		case 3:
			usb_stk11xx_write_registry(dev, 0x0000, 0x0088);
			break;
		case 4:
			usb_stk11xx_write_registry(dev, 0x0000, 0x0080);
			break;
	}
	usb_stk11xx_write_registry(dev, 0x0002, 0x0093);

	return 0;
	
}


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief Wake-up the camera.
 *
 * This function permits to wake-up the device.
 */
int dev_stk0408_camera_asleep(ECVSTK1160Controller *dev)
{
	int value;
	int value0;

	usb_stk11xx_read_registry(dev, 0x0104, &value);
	usb_stk11xx_read_registry(dev, 0x0105, &value);
	usb_stk11xx_read_registry(dev, 0x0106, &value);

	usb_stk11xx_read_registry(dev, 0x0100, &value);
	
	value = value & 0x7f;
	usb_stk11xx_write_registry(dev, 0x0100, value);

	usb_stk11xx_write_registry(dev, 0x0116, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0117, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0018, 0x0000);

	usb_stk11xx_read_registry(dev, 0x0002, &value);
	usb_stk11xx_read_registry(dev, 0x0000, &value0);
	usb_stk11xx_write_registry(dev, 0x0002, value);
	usb_stk11xx_read_registry(dev, 0x0000, &value0);

	return 0;
}


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief This function initializes the device for the stream.
 *
 * It's the start. This function has to be called at first, before
 * enabling the video stream.
 */
int dev_stk0408_init_camera(ECVSTK1160Controller *dev)
{
	dev_stk0408_camera_asleep(dev);

	dev_stk0408_configure_device(dev, 3);
	dev_stk0408_configure_device(dev, 4);
	dev_stk0408_configure_device(dev, 5);

	dev_stk0408_configure_device(dev, 6);
	
	return 0;
}

int dev_stk0408_check_device(ECVSTK1160Controller *dev)
{
	int i;
	int value;
	const int retry=2;
	
	for (i=0; i < retry; i++) {
		usb_stk11xx_read_registry(dev, 0x201, &value);

//writes to 204/204 return 4 on success
//writes to 208 return 1 on success

		if (value == 0x04 || value == 0x01) 
			return 1;

		if (value != 0x00)
		{
			STK_ERROR("Check device return error (0x0201 = %02X) !\n", value);
			return -1;
		}
//		msleep(10);
	}
	
	return 0;
}			


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief This function sets the default sensor settings
 *
 * We set some registers in using a I2C bus.
 * WARNING, the sensor settings can be different following the situation.
 */
int dev_stk0408_sensor_settings(ECVSTK1160Controller *dev)
{
	int i;
	int retok;
	int asize;
	
// PAL registers
	int const registers[] = {
		0x01,0x03,0x04,0x05,0x06,0x07,
		0x08,
		0x0a,0x0b,0x0c,0x0d,
		0x0e,
		0x0f,0x10,0x11,0x12,
		0x13,0x15,0x16,0x40,0x41,0x42,0x43,0x44,0x45,0x46,0x47,0x48,0x49,0x4a,0x4b,0x4c,
		0x4d,0x4e,0x4f,0x50,0x51,0x52,0x53,0x54,0x55,0x56,0x57,0x58,0x59,
		0x5a,
		0x5b };

	int const values[] = {
		0x08,0x33,0x00,0x00,0xe9,0x0d,
		(dev.isNTSCFormat ? 0x78 : 0x38),
		0x80,0x47,0x40,0x00,
		(dev.isPALNFormat ? 0x20 : 0x01),
		0x2a,0x00,0x0c,0xe7,
		0x00,0x00,0x00,0x02,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,0xff,
		0xff,0xff,0xff,0xff,0xff,0xff,0xff,0x55,0xff,0xff,0xff,0x40,0x54,
		(dev.isNTSCFormat ? 0x0a : 0x07),
		0x83 };

	asize = ARRAY_SIZE(values);

	for(i=0; i<asize; i++) {
		retok = dev_stk0408_write_saa(dev, registers[i], values[i]);
		
		if (retok != 1) {
			STK_ERROR("Load default sensor settings fail !\n");
			return -1;
		}
	}
	
	return 0;
}


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 ' * @brief This function permits to modify the settings of the camera.
 *
 * This functions permits to modify the settings :
 *   - brightness
 *   - contrast
 *   - white balance
 *   - ...
 */
int dev_stk0408_camera_settings(ECVSTK1160Controller *dev)
{
	dev_stk0408_set_camera_quality(dev);

	return 0;
}


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief This function permits to modify the settings of the camera.
 *
 */
int dev_stk0408_set_camera_quality(ECVSTK1160Controller *dev)
{
	usb_stk11xx_write_registry(dev, 0x0002, 0x0078);

//brightness
	dev_stk0408_write_saa(dev, 0x0a, dev->vsettings.brightness >> 8); //80
//contrast
	dev_stk0408_write_saa(dev, 0x0b, dev->vsettings.contrast >> 9); //40
//hue
	dev_stk0408_write_saa(dev, 0x0d, (dev->vsettings.colour - 32768) >> 8); //00
//saturation
	dev_stk0408_write_saa(dev, 0x0c, (dev->vsettings.hue) >> 9); //40
	
	STK_DEBUG("Set colour : %d\n", dev->vsettings.colour);
	STK_DEBUG("Set contrast : %d\n", dev->vsettings.contrast);
	STK_DEBUG("Set hue : %d\n", dev->vsettings.hue);
	STK_DEBUG("Set brightness : %d\n", dev->vsettings.brightness);

	return 1;
}

int dev_stk0408_set_camera_input(ECVSTK1160Controller *dev)
{
	dev_stk0408_write_saa(dev, 0x02, SAA7115FUSE0Antialias | SAA7115FUSE1Amplifier | SAA7115ModeForVideoSource(dev.videoSource));
	dev_stk0408_write_208(dev, 0x09);
	return 1;
}


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief This function permits to modify the settings of the camera.
 *
 * This functions permits to modify the frame rate per second.
 *
 */
int dev_stk0408_set_camera_fps(ECVSTK1160Controller *dev)
{
	//Unknown, setting FPS seems to have no effect
	return 0;
}


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief This function sets the device to start the stream.
 *
 * After the initialization of the device and the initialization of the video stream,
 * this function permits to enable the stream.
 */
int dev_stk0408_start_stream(ECVSTK1160Controller *dev)
{
	int value;
	int value_116, value_117;

	usb_stk11xx_read_registry(dev, 0x0116, &value_116);
	usb_stk11xx_read_registry(dev, 0x0117, &value_117);

	usb_stk11xx_write_registry(dev, 0x0116, 0x0000);
	usb_stk11xx_write_registry(dev, 0x0117, 0x0000);

	usb_stk11xx_read_registry(dev, 0x0100, &value);
	value |= 0x80;
	
//	msleep(0x1f4);
	usb_stk11xx_write_registry(dev, 0x0100, value);
//	msleep(0x64);
	
	usb_stk11xx_write_registry(dev, 0x0116, value_116);
	usb_stk11xx_write_registry(dev, 0x0117, value_117);

	return 0;
}


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief Reconfigure the camera before the stream.
 *
 * Before enabling the video stream, you have to reconfigure the device.
 */
int dev_stk0408_reconf_camera(ECVSTK1160Controller *dev)
{

	dev_stk0408_configure_device(dev, 6);

	dev_stk0408_camera_settings(dev);

	return 0;
}


/** 
 * @param dev Device structure
 * 
 * @returns 0 if all is OK
 *
 * @brief This function sets the device to stop the stream.
 *
 * You use the function start_stream to enable the video stream. So you
 * have to use the function stop_strem to disable the video stream.
 */
int dev_stk0408_stop_stream(ECVSTK1160Controller *dev)
{
	int value;

	usb_stk11xx_read_registry(dev, 0x0100, &value);
	value &= 0x7f;
	usb_stk11xx_write_registry(dev, 0x0100, value);
	msleep(5);
	
	return 0;
}
