import os

def rename_bytes_to_lua(root_dir):
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            if filename.endswith('.bytes'):
                old_path = os.path.join(dirpath, filename)
                new_path = os.path.join(dirpath, filename[:-6] + '.lua')
                os.rename(old_path, new_path)
                print(f'Renamed: {old_path} -> {new_path}')

if __name__ == "__main__":
    # Change this to your target directory if needed
    root_directory = r""
    rename_bytes_to_lua(root_directory)