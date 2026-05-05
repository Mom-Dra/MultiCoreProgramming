#pragma once

#include "common.h"
#include <opencv2/core.hpp>
#include <opencv2/highgui.hpp>
#include "ImageLoader.h"

using namespace cv;

class ImageViewer
{
private:
	Mat img;
	bool convertToMat(uchar* _img, int _width, int _height);
public:
	bool ShowImage(ImageLoader* _img, char* _title = NULL);
	bool ShowImage(uchar* _img, int _width, int _height, char* _title = NULL);
	bool writeImage(uchar* _img, int _width, int _height, char* _fileName);
};

