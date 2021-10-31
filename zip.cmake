file(SHA512 "${zip_path}.7z" zip_hash)
file(WRITE "${zip_path}.sha512" ${zip_hash})
file(APPEND "${hash_path}" "${dep_name}.7z:${zip_hash}\n")