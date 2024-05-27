# Replacing all newline: 0x0a found in the old zipped file with 0x0d0a for new zipped files on Windows
# Also replacing the file extention name in the new zipped file
# Created on 2024/05/23
# Last Updated on 2024/05/27
# Andrew Jan

# Define paths for input and output zip files
input_zip_path = 'd:\\src\\OLD_PDS_FILEs.zip'
output_zip_path = 'd:\\src\\NEW_PDS_FILESs.zip'

# Define the character combination to replace and the replacement
#old_combination = '\r\r\n'
old_combination = '\n'
new_combination = '\r\n'

# File name extention to be substituted in new zip
old_ext = 'TEXT'
new_ext = 'txt'

import zipfile

def replace_in_a_file(content, old, new):
    # This function replaces all occurrences of old with new in the content
    return content.replace(old, new)

def process_zip_replace(input_zip_path, output_zip_path, old, new):
    with zipfile.ZipFile(input_zip_path, 'r') as zip_read:
        with zipfile.ZipFile(output_zip_path, 'w') as zip_write:
            
            # Iterate over each file in the input zip
            for file_info in zip_read.infolist():
                print(file_info.filename)
               
                with zip_read.open(file_info) as file:
                    # Read the content of the file with errors='ignore'
                    file_content = file.read().decode('cp950', errors='ignore')
                    
                    # Replace the special character combination in the content
                    updated_content = replace_in_a_file(file_content, old, new)
                    
                    # Write the updated content back to the new zip file
                    zip_write.writestr(file_info.filename[:-len(old_ext)] + new_ext, updated_content.encode('cp950', errors='ignore'))
        
# Process the zip file
process_zip_replace(input_zip_path, output_zip_path, old_combination, new_combination)

