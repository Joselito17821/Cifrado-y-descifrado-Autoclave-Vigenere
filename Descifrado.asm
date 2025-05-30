.data
    msg_ingrese:    .asciiz "Ingrese la clave corta que usaste para el cifrado: "		#A message that asks the user to input the key used during encryption.
    clave_inicial:  .space 50									#holds the original short key entered by the user.
    inputFile:      .asciiz "criptogram.txt"
    outputFile:     .asciiz "decoded.txt"			#Filenames used for reading the encrypted text and writing the final decrypted message.
    buffer_in:      .space 1
    buffer_out:     .space 1		#One-character buffers for input and output operations.

    idx:            .word 0		#is the index used to traverse the extended key (clave_actual).
    write_index:    .word 0		#marks the current end of the extended key to keep adding new characters.
    clave_actual:   .space 100  #is the extended key that will grow using decrypted characters (Autoclave logic).

    success: .asciiz "\n>> Su descifrado fue completado con exito.\n"			#A success message shown after the decryption process is complete.

.text
.globl main

main:
    jal ingresar_clave
    jal remover_salto_de_linea
    jal copiar_clave
    jal abrir_archivos				#Modular structure using subroutine calls (jal) to keep the main function simple and clean.
    jal leer_y_descifrar
    jal cerrar_archivos

    li $v0, 4					# Display final message and then exit the program.
    la $a0, success
    syscall

    li $v0, 10
    syscall

# Show prompt asking for the short key used during encryption.
ingresar_clave:
    li $v0, 4				
    la $a0, msg_ingrese
    syscall

    li $v0, 8
    la $a0, clave_inicial		#Read the key from the user input and store it in clave_inicial.
    li $a1, 50
    syscall
    jr $ra

# Subrutine: remover_salto_de_linea
remover_salto_de_linea:
    la $t0, clave_inicial
buscar_nueva_linea:
    lb $t1, 0($t0)	#This removes the newline (\n, ASCII 10) left after pressing Enter. It ensures that the key string ends cleanly with a null terminator (\0).
    beqz $t1, fin_trim
    li $t2, 10
    beq $t1, $t2, reemplazar_cero
    addi $t0, $t0, 1
    j buscar_nueva_linea
reemplazar_cero:
    sb $zero, 0($t0)
fin_trim:
    jr $ra

# 
copiar_clave:
    la $t0, clave_inicial		#Copies character-by-character from clave_inicial to clave_actual.
    la $t1, clave_actual
    li $t2, 0
ciclo_copia:
    lb $t3, 0($t0)
    beqz $t3, fin_copia
    sb $t3, 0($t1)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    addi $t2, $t2, 1
    j ciclo_copia
fin_copia:
    sw $t2, write_index
    jr $ra

# Open criptogram.txt for reading.
abrir_archivos:
    li $v0, 13
    la $a0, inputFile
    li $a1, 0
    syscall
    move $s0, $v0
#Open decoded.txt for writing.
    li $v0, 13
    la $a0, outputFile
    li $a1, 1
    syscall
    move $s1, $v0
    jr $ra

# Read one character at a time from criptogram.txt. If end of file (EOF), stop the loop.
leer_y_descifrar:
ciclo_lectura:
    li $v0, 14
    move $a0, $s0
    la $a1, buffer_in
    li $a2, 1
    syscall
    beqz $v0, fin_lectura
#If the character is not in the printable ASCII range (32 to 126), skip decryption and write it unchanged.
    lb $t0, buffer_in
    li $t9, 32
    blt $t0, $t9, escribir_igual
    li $t9, 126
    bgt $t0, $t9, escribir_igual

    # Get the corresponding key character from the extended key.
    lw $t1, idx
    la $t2, clave_actual
    add $t3, $t2, $t1
    lb $t4, 0($t3)

    # Convertir a valores
    li $t9, 32
    sub $t5, $t0, $t9		# Ciphertext letter
    sub $t6, $t4, $t9		# Key letter

    sub $t7, $t5, $t6
    addi $t7, $t7, 95
    li $t8, 95				#P=(C?K+95)mod95
    divu $t7, $t8
    mfhi $t7
    add $t7, $t7, $t9
    sb $t7, buffer_out

    # Write the decrypted character into decoded.txt.
    li $v0, 15
    move $a0, $s1
    la $a1, buffer_out
    li $a2, 1
    syscall

    # As per Autoclave method, we grow the key by appending each newly decrypted character to the end of clave_actual.
    lw $t3, write_index
    la $t2, clave_actual
    add $t4, $t2, $t3
    sb $t7, 0($t4)
    addi $t3, $t3, 1
    sw $t3, write_index

    # Move to the next character.
    lw $t1, idx
    addi $t1, $t1, 1
    sw $t1, idx

    j ciclo_lectura
#If the character wasn't within the expected ASCII range, write it unchanged.
escribir_igual:
    sb $t0, buffer_out
    li $v0, 15
    move $a0, $s1
    la $a1, buffer_out
    li $a2, 1
    syscall
    j ciclo_lectura

fin_lectura:
    jr $ra

# Close both input and output files.
cerrar_archivos:
    li $v0, 16
    move $a0, $s0
    syscall

    li $v0, 16
    move $a0, $s1
    syscall
    jr $ra
