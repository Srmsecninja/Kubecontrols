import subprocess
import os

import subprocess
import os

def apply_yaml_file(file_path):
    """Apply a YAML file using kubectl."""
    try:
        subprocess.run(["kubectl", "apply", "-f", file_path], check=True)
        print(f"Successfully applied {file_path}")
    except subprocess.CalledProcessError as e:
        print(f"Error applying {file_path}: {e}")

def main():
    # Directory containing your YAML files
    yaml_directory = "./yaml_files"

    # Separate ConstraintTemplate and Constraint files based on filenames
    constraint_templates = []
    constraints = []

    for filename in os.listdir(yaml_directory):
        if filename.endswith('.yaml'):
            file_path = os.path.join(yaml_directory, filename)
            if 'template' in filename.lower():
                constraint_templates.append(file_path)
            else:
                constraints.append(file_path)

    # Apply ConstraintTemplate files first
    for template in constraint_templates:
        apply_yaml_file(template)

    # Apply Constraint files second
    for constraint in constraints:
        apply_yaml_file(constraint)

if __name__ == "__main__":
    main()
