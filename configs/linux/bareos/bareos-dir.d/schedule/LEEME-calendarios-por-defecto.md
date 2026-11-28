# Calendarios por defecto de Bareos desactivados (27/11/2026)

En BKP01 se anadio `Enabled = no` debajo de `Name` en:

- schedule/WeeklyCycle.conf
- schedule/WeeklyCycleAfterBackup.conf

Se desactivan en lugar de borrarse para poder volver atras y para que una actualizacion del paquete no los recree.
