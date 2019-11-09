file(SHA512 "${zip_path}" zip_hash)
file(APPEND "${hash_path}" "\"${dep_name}.7z:${zip_hash}\"\n")