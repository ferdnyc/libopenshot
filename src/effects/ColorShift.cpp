/**
 * @file
 * @brief Source file for Color Shift effect class
 * @author Jonathan Thomas <jonathan@openshot.org>
 *
 * @ref License
 */

/* LICENSE
 *
 * Copyright (c) 2008-2019 OpenShot Studios, LLC
 * <http://www.openshotstudios.com/>. This file is part of
 * OpenShot Library (libopenshot), an open-source project dedicated to
 * delivering high quality video editing and animation solutions to the
 * world. For more information visit <http://www.openshot.org/>.
 *
 * OpenShot Library (libopenshot) is free software: you can redistribute it
 * and/or modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * OpenShot Library (libopenshot) is distributed in the hope that it will be
 * useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with OpenShot Library. If not, see <http://www.gnu.org/licenses/>.
 */

#include "../../include/effects/ColorShift.h"

#include "../../include/Frame.h"
#include "../../include/KeyFrame.h"

#include <cmath>

using namespace openshot;

/// Blank constructor, useful when using Json to load the effect properties
ColorShift::ColorShift() : red_x(-0.05), red_y(0.0), green_x(0.05), green_y(0.0), blue_x(0.0), blue_y(0.0), alpha_x(0.0), alpha_y(0.0) {
	// Init effect properties
	init_effect_details();
}

// Default constructor
ColorShift::ColorShift(Keyframe red_x, Keyframe red_y, Keyframe green_x, Keyframe green_y, Keyframe blue_x, Keyframe blue_y, Keyframe alpha_x, Keyframe alpha_y) :
		red_x(red_x), red_y(red_y), green_x(green_x), green_y(green_y), blue_x(blue_x), blue_y(blue_y), alpha_x(alpha_x), alpha_y(alpha_y)
{
	// Init effect properties
	init_effect_details();
}

// Init effect settings
void ColorShift::init_effect_details()
{
	/// Initialize the values of the EffectInfo struct.
	InitEffectInfo();

	/// Set the effect info
	info.class_name = "ColorShift";
	info.name = "Color Shift";
	info.description = "Shift the colors of an image up, down, left, and right (with infinite wrapping).";
	info.has_audio = false;
	info.has_video = true;
}

// This method is required for all derived classes of EffectBase, and returns a
// modified openshot::Frame object
std::shared_ptr<Frame> ColorShift::GetFrame(std::shared_ptr<Frame> frame, int64_t frame_number)
{
	// Get the frame's image
	std::shared_ptr<QImage> frame_image = frame->GetImage();
	const unsigned char *pixels = frame_image->constBits();

	// Get image size
	int w = frame_image->width();
	int h = frame_image->height();

	// Get the current shift amounts, and convert to pixel offsets
	// stored in an array [Rx, Ry, Gx, Gy, Bx, By, Ax, Ay]
	const long offsets[8] = {
		// Red x and y offsets
		std::lround(w * std::fmod(red_x.GetValue(frame_number), 1.0)),
		std::lround(h * std::fmod(red_y.GetValue(frame_number), 1.0)),
		// Green x and y offsets
		std::lround(w * std::fmod(green_x.GetValue(frame_number), 1.0)),
		std::lround(h * std::fmod(green_y.GetValue(frame_number), 1.0)),
		// Blue x and y offsets
		std::lround(w * std::fmod(blue_x.GetValue(frame_number), 1.0)),
		std::lround(h * std::fmod(blue_y.GetValue(frame_number), 1.0)),
		// Alpha x and y offsets
		std::lround(w * std::fmod(alpha_x.GetValue(frame_number), 1.0)),
		std::lround(h * std::fmod(alpha_y.GetValue(frame_number), 1.0))
	};

	// Make a writable copy of the image pixel array as our output memory
	unsigned char *output = frame_image->bits();

	// Loop through rows of pixels
	for (int row = 0; row < h; row++) {
		for (int col = 0; col < w; col++) {

			int pixel = row * col * 4;

			// Compute byte location for source pixel, per channel
			int red_x = row + std::abs(offsets[0]) >= w ? row + offsets[0] : w - row + offsets[0];
			int red_y = col + std::abs(offsets[1]) >= h ? col + offsets[1] : h - row + offsets[1];
			int green_x = row + std::abs(offsets[2]) >= w ? row + offsets[2] : w - row + offsets[2];
			int green_y = col + std::abs(offsets[3]) >= h ? col + offsets[3] : h - row + offsets[3];
			int blue_x = row + std::abs(offsets[4]) >= w ? row + offsets[4] : w - row + offsets[4];
			int blue_y = col + std::abs(offsets[5]) >= h ? col + offsets[5] : h - row + offsets[5];
			int alpha_x = row + std::abs(offsets[6]) >= w ? row + offsets[6] : w - row + offsets[6];
			int alpha_y = col + std::abs(offsets[7]) >= h ? col + offsets[7] : h - row + offsets[7];

			// Copy channel values from source pixel locations
			output[(row * w + col) * 4] = pixels[(red_y * w + red_x) * 4];
			output[(row * w + col) * 4 + 1] = pixels[(green_y * w + green_x) * 4 + 1];
			output[(row * w + col) * 4 + 2] = pixels[(blue_y * w + blue_x) * 4 + 2];
			output[(row * w + col) * 4 + 3] = pixels[(alpha_y * w + alpha_x) * 4 + 3];
		}
	}

	// return the modified frame
	return frame;
}

// Generate JSON string of this object
std::string ColorShift::Json() {

	// Return formatted string
	return JsonValue().toStyledString();
}

// Generate Json::JsonValue for this object
Json::Value ColorShift::JsonValue() {

	// Create root json object
	Json::Value root = EffectBase::JsonValue(); // get parent properties
	root["type"] = info.class_name;
	root["red_x"] = red_x.JsonValue();
	root["red_y"] = red_y.JsonValue();
	root["green_x"] = green_x.JsonValue();
	root["green_y"] = green_y.JsonValue();
	root["blue_x"] = blue_x.JsonValue();
	root["blue_y"] = blue_y.JsonValue();
	root["alpha_x"] = alpha_x.JsonValue();
	root["alpha_y"] = alpha_y.JsonValue();

	// return JsonValue
	return root;
}

// Load JSON string into this object
void ColorShift::SetJson(std::string value) {

	// Parse JSON string into JSON objects
	Json::Value root;
	Json::CharReaderBuilder rbuilder;
	Json::CharReader* reader(rbuilder.newCharReader());

	std::string errors;
	bool success = reader->parse( value.c_str(),
                 value.c_str() + value.size(), &root, &errors );
	delete reader;

	if (!success)
		// Raise exception
		throw InvalidJSON("JSON could not be parsed (or is invalid)");

	try
	{
		// Set all values that match
		SetJsonValue(root);
	}
	catch (const std::exception& e)
	{
		// Error parsing JSON (or missing keys)
		throw InvalidJSON("JSON is invalid (missing keys or invalid data types)");
	}
}

// Load Json::JsonValue into this object
void ColorShift::SetJsonValue(Json::Value root) {

	// Set parent data
	EffectBase::SetJsonValue(root);

	// Set data from Json (if key is found)
	if (!root["red_x"].isNull())
		red_x.SetJsonValue(root["red_x"]);
	if (!root["red_y"].isNull())
		red_y.SetJsonValue(root["red_y"]);
	if (!root["green_x"].isNull())
		green_x.SetJsonValue(root["green_x"]);
	if (!root["green_y"].isNull())
		green_y.SetJsonValue(root["green_y"]);
	if (!root["blue_x"].isNull())
		blue_x.SetJsonValue(root["blue_x"]);
	if (!root["blue_y"].isNull())
		blue_y.SetJsonValue(root["blue_y"]);
	if (!root["alpha_x"].isNull())
		alpha_x.SetJsonValue(root["alpha_x"]);
	if (!root["alpha_y"].isNull())
		alpha_y.SetJsonValue(root["alpha_y"]);
}

// Get all properties for a specific frame
std::string ColorShift::PropertiesJSON(int64_t requested_frame) {

	// Generate JSON properties list
	Json::Value root;
	root["id"] = add_property_json("ID", 0.0, "string", Id(), NULL, -1, -1, true, requested_frame);
	root["position"] = add_property_json("Position", Position(), "float", "", NULL, 0, 1000 * 60 * 30, false, requested_frame);
	root["layer"] = add_property_json("Track", Layer(), "int", "", NULL, 0, 20, false, requested_frame);
	root["start"] = add_property_json("Start", Start(), "float", "", NULL, 0, 1000 * 60 * 30, false, requested_frame);
	root["end"] = add_property_json("End", End(), "float", "", NULL, 0, 1000 * 60 * 30, false, requested_frame);
	root["duration"] = add_property_json("Duration", Duration(), "float", "", NULL, 0, 1000 * 60 * 30, true, requested_frame);

	// Keyframes
	root["red_x"] = add_property_json("Red X Shift", red_x.GetValue(requested_frame), "float", "", &red_x, -1, 1, false, requested_frame);
	root["red_y"] = add_property_json("Red Y Shift", red_y.GetValue(requested_frame), "float", "", &red_y, -1, 1, false, requested_frame);
	root["green_x"] = add_property_json("Green X Shift", green_x.GetValue(requested_frame), "float", "", &green_x, -1, 1, false, requested_frame);
	root["green_y"] = add_property_json("Green Y Shift", green_y.GetValue(requested_frame), "float", "", &green_y, -1, 1, false, requested_frame);
	root["blue_x"] = add_property_json("Blue X Shift", blue_x.GetValue(requested_frame), "float", "", &blue_x, -1, 1, false, requested_frame);
	root["blue_y"] = add_property_json("Blue Y Shift", blue_y.GetValue(requested_frame), "float", "", &blue_y, -1, 1, false, requested_frame);
	root["alpha_x"] = add_property_json("Alpha X Shift", alpha_x.GetValue(requested_frame), "float", "", &alpha_x, -1, 1, false, requested_frame);
	root["alpha_y"] = add_property_json("Alpha Y Shift", alpha_y.GetValue(requested_frame), "float", "", &alpha_y, -1, 1, false, requested_frame);

	// Return formatted string
	return root.toStyledString();
}
