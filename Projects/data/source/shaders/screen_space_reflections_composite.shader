type = "render"

include = [ "shadow_mapping" ]

passes =
{
	composite =
	{
		vs = "vs_func"
		ps = "ps_func"
	}
}

instance = 
{
	constant_buffers = 
	{
		InstanceCB = 
		{
			//input_texel_size = float2
			project_to_pixel = float4x4
			z_thickness		 = float
		}
	}
	
	resources = 
	{
		color_texture = { type = Texture2D }
		reflection_texture = { type = Texture2D }
		normal_texture = { type = Texture2D }
		depth_texture = { type = Texture2D }
	}

	options =
	[
	]
}

snippets =
{
	ps_input =
	{
		hlsl =
		"""
			struct PS_INPUT
			{
				float4 position  : SV_Position;
				float2 tex_coord : TEXCOORD0;
				float3 view_ray  : TEXCOORD1;
			};
		"""
	}

	vs_func =
	{
		include = [ps_input]

		hlsl =
		"""
			
			PS_INPUT vs_main(uint vertex_id : SV_VERTEXID)
			{
				PS_INPUT output;
				output.tex_coord =  float2((vertex_id << 1) & 2, vertex_id & 2);
    			output.position  = float4(output.tex_coord * float2(2,-2) + float2(-1,1), 1, 1);

    			float3 position_ws = mul(output.position, inv_proj).xyz;

    			output.view_ray = float3(position_ws.xy / position_ws.z, 1.0f);

				return output;
			}
		"""
	}

	ps_func =
	{
		include = ["samplers", "ps_input", "depth_utilities", "gbuffer"]

		hlsl =
		"""
			float3 ps_main( PS_INPUT input) : SV_TARGET0
			{
				float3 color = color_texture.Load(uint3(input.position.xy, 0)).rgb;

				float roughness = GBUFFER_GET_ROUGHNESS( normal_texture.Load(uint3(input.position.xy, 0)) );

				float4 reflection = reflection_texture.SampleLevel(tri_linear_clamp_sampler, input.tex_coord, roughness * 5);

				return color + reflection.rgb * reflection.a;
			}
		"""
	}
}