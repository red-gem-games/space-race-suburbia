// Harmonizer Shader

shader_type spatial;
render_mode blend_mix, cull_back, unshaded, specular_schlick_ggx;

uniform vec4 text_color : source_color = vec4(0.0, 1.0, 0.0, 3.0);
uniform vec4 bg_color : source_color = vec4(0.0, 0.1, 0.0, 0.1);  
uniform vec4 glass_tint : source_color = vec4(0.2, 0.5, 0.2, 0.35);
uniform float glass_roughness : hint_range(0.0, 1.0) = 0.05;
uniform float glass_metallic : hint_range(0.0, 1.0) = 0.0;
uniform float refraction_amount : hint_range(0.0, 1.0) = 0.1;
uniform float scroll_speed : hint_range(-2.0, 2.0) = 0.1;
uniform float char_width : hint_range(0.02, 0.3) = 0.08;
uniform float char_spacing : hint_range(0.0, 1.0) = 0.3;
uniform float text_height : hint_range(0.01, 0.5) = 0.15;
uniform float vertical_position : hint_range(0.0, 1.0) = 0.5;
uniform float glow_intensity : hint_range(0.0, 5.0) = 3.0;

// Dynamic text support
uniform int text_chars[250];
uniform int text_length : hint_range(1, 250) = 25;

bool check_pixel(int char_code, int px, int py) {
	// LETTERS
	// A
	if (char_code == 65) {
		if (py == 0 && (px >= 1 && px <= 3)) return true;
		if (py == 1 && (px == 0 || px == 4)) return true;
		if (py == 2) return true;
		if (py == 3 && (px == 0 || px == 4)) return true;
		if (py == 4 && (px == 0 || px == 4)) return true;
	}
	// B
	else if (char_code == 66) {
		if (px == 0) return true;
		if (py == 0 && px <= 3) return true;
		if (py == 2 && px <= 3) return true;
		if (py == 4 && px <= 3) return true;
		if ((py == 1 || py == 3) && px == 4) return true;
	}
	// C
	else if (char_code == 67) {
		if (py == 0 && px >= 1) return true;
		if (py == 4 && px >= 1) return true;
		if ((py == 1 || py == 2 || py == 3) && px == 0) return true;
	}
	// D
	else if (char_code == 68) {
		if (px == 0) return true;
		if (py == 0 && px <= 3) return true;
		if (py == 4 && px <= 3) return true;
		if ((py == 1 || py == 2 || py == 3) && px == 4) return true;
	}
	// E
	else if (char_code == 69) {
		if (px == 0) return true;
		if (py == 0 || py == 2 || py == 4) return true;
	}
	// F
	else if (char_code == 70) {
		if (px == 0) return true;
		if (py == 0 || py == 2) return true;
	}
	// G
	else if (char_code == 71) {
		if (py == 0 && px >= 1) return true;
		if (py == 4 && px >= 1) return true;
		if ((py == 1 || py == 2 || py == 3) && px == 0) return true;
		if ((py == 2 || py == 3) && px >= 3) return true;
	}
	// H
	else if (char_code == 72) {
		if (px == 0 || px == 4) return true;
		if (py == 2) return true;
	}
	// I
	else if (char_code == 73) {
		if (py == 0 || py == 4) return true;
		if (px == 2) return true;
	}
	// J
	else if (char_code == 74) {
		if (py == 0) return true;
		if (px == 2 && py <= 3) return true;
		if (py == 4 && (px >= 0 && px <= 2)) return true;
	}
	// K
	else if (char_code == 75) {
		if (px == 0) return true;
		if (py == 2 && px == 1) return true;
		if (py == 1 && px == 3) return true;
		if (py == 0 && px == 4) return true;
		if (py == 3 && px == 3) return true;
		if (py == 4 && px == 4) return true;
	}
	// L
	else if (char_code == 76) {
		if (px == 0) return true;
		if (py == 4) return true;
	}
	// M
	else if (char_code == 77) {
		if (px == 0 || px == 4) return true;
		if (py == 0 && (px == 1 || px == 3)) return true;
		if (py == 1 && px == 2) return true;
	}
	// N
	else if (char_code == 78) {
		if (px == 0 || px == 4) return true;
		if (py == 1 && px == 1) return true;
		if (py == 2 && px == 2) return true;
		if (py == 3 && px == 3) return true;
	}
	// O
	else if (char_code == 79) {
		if (py == 0 && (px >= 1 && px <= 3)) return true;
		if ((py == 1 || py == 2 || py == 3) && (px == 0 || px == 4)) return true;
		if (py == 4 && (px >= 1 && px <= 3)) return true;
	}
	// P
	else if (char_code == 80) {
		if (px == 0) return true;
		if (py == 0 && px <= 3) return true;
		if (py == 2 && px <= 3) return true;
		if (py == 1 && px == 4) return true;
	}
	// Q
	else if (char_code == 81) {
		if (py == 0 && (px >= 1 && px <= 3)) return true;
		if ((py == 1 || py == 2) && (px == 0 || px == 4)) return true;
		if (py == 3 && (px == 0 || px == 3 || px == 4)) return true;
		if (py == 4 && (px >= 1 && px <= 4)) return true;
	}
	// R
	else if (char_code == 82) {
		if (px == 0) return true;
		if (py == 0 && px <= 3) return true;
		if (py == 2 && px <= 3) return true;
		if (py == 1 && px == 4) return true;
		if (py == 3 && px == 3) return true;
		if (py == 4 && px == 4) return true;
	}
	// S
	else if (char_code == 83) {
		if (py == 0 && px >= 1) return true;
		if (py == 1 && px == 0) return true;
		if (py == 2) return true;
		if (py == 3 && px == 4) return true;
		if (py == 4 && px <= 3) return true;
	}
	// T
	else if (char_code == 84) {
		if (py == 0) return true;
		if (px == 2) return true;
	}
	// U
	else if (char_code == 85) {
		if ((py <= 3) && (px == 0 || px == 4)) return true;
		if (py == 4 && (px >= 1 && px <= 3)) return true;
	}
	// V
	else if (char_code == 86) {
		if ((py <= 2) && (px == 0 || px == 4)) return true;
		if (py == 3 && (px == 1 || px == 3)) return true;
		if (py == 4 && px == 2) return true;
	}
	// W
	else if (char_code == 87) {
		if (px == 0 || px == 4) return true;
		if (py == 3 && px == 2) return true;
		if (py == 4 && (px == 1 || px == 3)) return true;
	}
	// X
	else if (char_code == 88) {
		if ((py == 0 || py == 4) && (px == 0 || px == 4)) return true;
		if ((py == 1 || py == 3) && (px == 1 || px == 3)) return true;
		if (py == 2 && px == 2) return true;
	}
	// Y
	else if (char_code == 89) {
		if ((py == 0 || py == 1) && (px == 0 || px == 4)) return true;
		if (py == 2 && px == 2) return true;
		if ((py == 3 || py == 4) && px == 2) return true;
	}
	// Z
	else if (char_code == 90) {
		if (py == 0 || py == 4) return true;
		if (py == 1 && px == 3) return true;
		if (py == 2 && px == 2) return true;
		if (py == 3 && px == 1) return true;
	}
	
	// NUMBERS
	// 0
	else if (char_code == 48) {
		if (py == 0 && (px >= 1 && px <= 3)) return true;
		if ((py >= 1 && py <= 3) && (px == 0 || px == 4)) return true;
		if (py == 4 && (px >= 1 && px <= 3)) return true;
	}
	// 1
	else if (char_code == 49) {
		if (py == 0 && (px == 1 || px == 2)) return true;
		if (px == 2) return true;
		if (py == 4) return true;
	}
	// 2
	else if (char_code == 50) {
		if (py == 0) return true;
		if (py == 1 && px == 4) return true;
		if (py == 2) return true;
		if (py == 3 && px == 0) return true;
		if (py == 4) return true;
	}
	// 3
	else if (char_code == 51) {
		if (py == 0 || py == 2 || py == 4) return true;
		if ((py == 1 || py == 3) && px == 4) return true;
	}
	// 4
	else if (char_code == 52) {
		if ((py <= 2) && px == 0) return true;
		if (py == 2) return true;
		if (px == 4) return true;
	}
	// 5
	else if (char_code == 53) {
		if (py == 0) return true;
		if (py == 1 && px == 0) return true;
		if (py == 2) return true;
		if (py == 3 && px == 4) return true;
		if (py == 4 && px <= 3) return true;
	}
	// 6
	else if (char_code == 54) {
		if (py == 0 && px >= 1) return true;
		if ((py == 1 || py == 2 || py == 3) && px == 0) return true;
		if (py == 2) return true;
		if (py == 3 && px == 4) return true;
		if (py == 4 && (px >= 1 && px <= 3)) return true;
	}
	// 7
	else if (char_code == 55) {
		if (py == 0) return true;
		if (py == 1 && px == 4) return true;
		if (py == 2 && px == 3) return true;
		if (py == 3 && px == 2) return true;
		if (py == 4 && px == 2) return true;
	}
	// 8
	else if (char_code == 56) {
		if ((py == 0 || py == 2 || py == 4) && (px >= 1 && px <= 3)) return true;
		if ((py == 1 || py == 3) && (px == 0 || px == 4)) return true;
	}
	// 9
	else if (char_code == 57) {
		if (py == 0 && (px >= 1 && px <= 3)) return true;
		if (py == 1 && (px == 0 || px == 4)) return true;
		if (py == 2) return true;
		if (py == 3 && px == 4) return true;
		if (py == 4 && px <= 3) return true;
	}
	
	// PUNCTUATION & SYMBOLS
	// Period .
	else if (char_code == 46) {
		if (py == 4 && px == 2) return true;
	}
	// Comma ,
	else if (char_code == 44) {
	if (py == 4 && px == 2) return true;
	if (py == 3 && px == 3) return true;
	}
	// Apostrophe '
	else if (char_code == 39) {
		if (py == 0 && px == 2) return true;
		if (py == 1 && px == 2) return true;
	}
	// Exclamation !
	else if (char_code == 33) {
		if (px == 2 && py <= 2) return true;
		if (py == 4 && px == 2) return true;
	}
	// Question ?
	else if (char_code == 63) {
		if (py == 0 && (px >= 1 && px <= 3)) return true;
		if (py == 1 && px == 4) return true;
		if (py == 2 && px == 2) return true;
		if (py == 4 && px == 2) return true;
	}
	// Colon :
	else if (char_code == 58) {
		if (py == 1 && px == 2) return true;
		if (py == 3 && px == 2) return true;
	}
	// Hyphen/Dash -
	else if (char_code == 45) {
		if (py == 2) return true;
	}
	// Slash /
	else if (char_code == 47) {
		if (py == 4 && px == 0) return true;
		if (py == 3 && px == 1) return true;
		if (py == 2 && px == 2) return true;
		if (py == 1 && px == 3) return true;
		if (py == 0 && px == 4) return true;
	}
	// Plus +
	else if (char_code == 43) {
		if (py == 2) return true;
		if (px == 2 && (py >= 1 && py <= 3)) return true;
	}
	// Equals =
	else if (char_code == 61) {
		if (py == 1 || py == 3) return true;
	}
	// SPACE
	else if (char_code == 32) {
		return false;
	}
	
	return false;
}

void fragment() {
	// Scroll the text horizontally around the capsule
	float scroll_offset = TIME * scroll_speed;
	
	// DON'T use fract() - let it keep scrolling through the full text array
	float scroll_uv = UV.x + scroll_offset;
	
	// Define text area
	float text_area_start = vertical_position - text_height / 2.0;
	float text_area_end = vertical_position + text_height / 2.0;
	
	// Check if we're in the text display area
	if (UV.y < text_area_start || UV.y > text_area_end) {
		ALBEDO = mix(bg_color.rgb, glass_tint.rgb, 0.5);
		ALPHA = glass_tint.a;
		ROUGHNESS = glass_roughness;
		METALLIC = glass_metallic;
	} else {
		// Character Calculation - now scroll_uv can be > 1.0
		float char_position = scroll_uv / char_width;
		int char_index = int(char_position) % text_length;
		
		// Position within current character
		float local_x = fract(char_position);
		
		// Spacing
		if (local_x > (1.0 - char_spacing)) {
			ALBEDO = mix(bg_color.rgb, glass_tint.rgb, 0.3);
			ALPHA = bg_color.a;
			ROUGHNESS = glass_roughness;
			METALLIC = glass_metallic;
		} else {
			// Remap local_x
			local_x = local_x / (1.0 - char_spacing);
			
			float local_y = (UV.y - text_area_start) / (text_area_end - text_area_start);
			
			int pixel_x = int(local_x * 5.0);
			int pixel_y = int(local_y * 5.0);
			
			// Get current character
			int current_char = text_chars[char_index];
			
			// Check if this pixel should be lit
			bool is_text = check_pixel(current_char, pixel_x, pixel_y);
			
			// Choose color
			if (is_text) {
				ALBEDO = text_color.rgb;
				EMISSION = text_color.rgb * glow_intensity;
				ALPHA = text_color.a;
				ROUGHNESS = 0.0;
			} else {
				ALBEDO = mix(bg_color.rgb, glass_tint.rgb, 0.3);
				ALPHA = bg_color.a;
				ROUGHNESS = glass_roughness;
				METALLIC = glass_metallic;
			}
		}
	}
}