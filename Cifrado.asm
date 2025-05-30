.data
    msg_ingrese:    .asciiz "Ingrese cualquier clave corta en ingles y en MAYUSCULAS: "    #This is the message displayed to the user asking for the encryption key.
    clave_inicial:  .space 50							#clave_inicial is where the user input key is stored.
    inputFile:      .asciiz "input.txt"
    outputFile:     .asciiz "criptogram.txt"					#File names for reading the original message and writing the encrypted result.
    buffer_in:      .space 1							#Buffers to read and write one character at a time from/to the files.
    buffer_out:     .space 1

    idx:            .word 0		#is the index used to access the current character in clave_actual.
    write_index:    .word 0		#is where we append new characters to the extended key.
    clave_actual:   .space 100

    success:        .asciiz "\n>> Su cifrado fue completado exitosamente.\n"		#Final message printed on successful encryption.

.text
.globl main

main:
    # Show message and enter password
    jal ingresar_clave

   # Remove line break
    jal remover_salto_de_linea

    # Copy key to clave_actual
    jal copiar_clave							#This is your main logic, neatly organized with procedure calls using jal.
									#Each subroutine handles one task, following structured programming principles.
    # Open files
    jal abrir_archivos

# Read and encrypt characters
    jal leer_y_cifrar

    # Close files
    jal cerrar_archivos

    # Final message
    li $v0, 4
    la $a0, success
    syscall

    li $v0, 10
    syscall

# ingresar_clave
ingresar_clave:
    li $v0, 4
    la $a0, msg_ingrese			#Displays the message asking for the key.
    syscall

    li $v0, 8
    la $a0, clave_inicial	#Reads up to 50 characters from the user input and stores them in clave_inicial.
    li $a1, 50
    syscall
    jr $ra

# 
remover_salto_de_linea:
    la $t0, clave_inicial
search_newline:
    lb $t1, 0($t0)
    beqz $t1, end_trim
    li $t2, 10
    beq $t1, $t2, replace_zero			#Ensures that the key ends with a null character (\0) instead of a newline. Prevents parsing issues later.
    addi $t0, $t0, 1
    j search_newline
replace_zero:
    sb $zero, 0($t0)
end_trim:
    jr $ra

# Sets up registers to copy from the input key to the clave_actual.
copiar_clave:
    la $t0, clave_inicial
    la $t1, clave_actual
    li $t2, 0
copy_loop:
    lb $t3, 0($t0)
    beqz $t3, done_copy
    sb $t3, 0($t1)		#Copies each character and updates the index write_index so we know how many key characters we’ve stored.
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    j copy_loop
done_copy:
    sw $t2, write_index
    jr $ra

# Opens input.txt for reading. File descriptor stored in $s0.
abrir_archivos:
    li $v0, 13
    la $a0, inputFile
    li $a1, 0
    syscall
    move $s0, $v0

    li $v0, 13
    la $a0, outputFile		#Opens criptogram.txt for writing. File descriptor stored in $s1.
    li $a1, 1
    syscall
    move $s1, $v0
    jr $ra

# Reads one character from input.txt. Ends loop if EOF (end of file).
leer_y_cifrar:
read_loop:
    li $v0, 14
    move $a0, $s0
    la $a1, buffer_in
    li $a2, 1
    syscall
    beqz $v0, end_read
#Filters characters: only encrypts printable ASCII characters (32–126).
    lb $t0, buffer_in
    li $t9, 32
    blt $t0, $t9, write_same		
    li $t9, 126
    bgt $t0, $t9, write_same

    # Gets the next character from clave_actual.
    lw $t1, idx
    la $t2, clave_actual
    add $t3, $t2, $t1
    lb $t4, 0($t3)

    # Convertir a valores
    li $t9, 32
    sub $t5, $t0, $t9	# Convert M to 0–94
    sub $t6, $t4, $t9	#Convert K to 0–94

    add $t7, $t5, $t6
    li $t8, 95
    divu $t7, $t8
    mfhi $t7		## C = (M + K) % 95
    add $t7, $t7, $t9
    sb $t7, buffer_out

    # Writes the encrypted character to criptogram.txt.
    li $v0, 15
    move $a0, $s1
    la $a1, buffer_out
    li $a2, 1
    syscall

    # Autoclave-style: we append each original message character to the key.
    lw $t3, write_index
    la $t2, clave_actual
    add $t4, $t2, $t3
    sb $t0, 0($t4)
    addi $t3, $t3, 1
    sw $t3, write_index

    # ncrease index and loop
    lw $t1, idx
    addi $t1, $t1, 1
    sw $t1, idx

    j read_loop
#Writes unmodified characters to output (spaces, punctuation, etc).
write_same:
    sb $t0, buffer_out
    li $v0, 15
    move $a0, $s1
    la $a1, buffer_out
    li $a2, 1
    syscall
    j read_loop

end_read:
    jr $ra

# Closes both input and output files.
cerrar_archivos:
    li $v0, 16
    move $a0, $s0
    syscall

    li $v0, 16
    move $a0, $s1
    syscall
    jr $ra
