import os
import sys

def read_env(file_path):
    """Reads the environment variables from the .env file."""
    env_vars = {}
    with open(file_path) as file:
        for line in file:
            # Ignore empty lines and comments
            if line.strip() and not line.startswith('#'):
                # Split each line into key and value
                key, value = line.strip().split('=', 1)
                env_vars[key] = value
    return env_vars

def replace_yaml_vars(yaml_content, env_vars):
    """Replaces placeholders in the YAML content with corresponding environment variable values."""
    for key, value in env_vars.items():
        # Placeholder format: ${VARIABLE_NAME}
        placeholder = "${" + key + "}"
        yaml_content = yaml_content.replace(placeholder, value)
    return yaml_content

def main():
    # Ensure the script is called with exactly one command-line argument
    if len(sys.argv) != 4:
        print("Usage: python decode_yaml.py <input_yaml_file_path> <output_yaml_file_path> <env_filepath>")
        sys.exit(1)
    
    input_yaml_file_path = sys.argv[1]  # Get the input file path from the command-line argument
    output_yaml_file_path = sys.argv[2]  # Get the output file path from the command-line argument
    env_file_path = sys.argv[3]  # Get the .env file path from the command-line argument
    # env_file_path = '.env'  # Hardcoded path to the .env file
    # input_yaml_file_path = 'values.ntua.encoded.yml'  # Hardcoded path to the YAML file
    
    # Read environment variables from the .env file
    env_vars = read_env(env_file_path)
    
    # Read the original YAML content
    with open(input_yaml_file_path) as file:
        yaml_content = file.read()

    # Temporarily replace {{ .Values.host }} to prevent accidental replacement
    # yaml_content = yaml_content.replace('{{ .Values.host }}', 'TEMP_HOST_PLACEHOLDER')

    # Replace other placeholders in the YAML content
    updated_yaml_content = replace_yaml_vars(yaml_content, env_vars)
    
    # Restore the original {{ .Values.host }} placeholder
    # updated_yaml_content = updated_yaml_content.replace('TEMP_HOST_PLACEHOLDER', '{{ .Values.host }}')
    
    # Write the updated YAML content to the specified output file
    with open(output_yaml_file_path, 'w') as file:
        file.write(updated_yaml_content)
    
    print(f"Updated YAML file saved to {output_yaml_file_path}")

if __name__ == '__main__':
    main()
