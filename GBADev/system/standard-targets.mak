######################################
# Standard Makefile Targets for HAM
######################################

#
# Build Targets
#



ifeq ($(USE_KRAWALL),yes) 
$(PROGNAME).$(EXT) : $(PROGNAME).elf 
	$(OBJCOPY) -v -O binary $(PROGNAME).elf $(PROGNAME).$(EXT) 
else
$(PROGNAME).$(EXT) : $(PROGNAME).elf 
	$(OBJCOPY) -v -O binary $(PROGNAME).elf $(PROGNAME).$(EXT) 
endif
#
# If Krawall support wanted, also compile samples.s and instruments.s and link Krawall lib
#
ifeq ($(USE_KRAWALL),yes) 

 LDFLAGS += $(ADD_LDFLAGS) $(LIBDIR) --script $(HAMDIR)/system/lnkscript-krawall

ifeq ($(KRAWALL_IS_REGISTERED),yes)

#
# registered
#

ifeq ($(findstring .xm,$(KRAWALL_FILES)),.xm)

   KRAWALL_USED_XM=yes
   KRAWALL_OFILES=$(KRAWALL_FILES:.xm=.o) samples.o instruments.o

else
ifeq ($(findstring .s3m,$(KRAWALL_FILES)),.s3m)

    KRAWALL_USED_S3M=yes
    KRAWALL_OFILES=$(KRAWALL_FILES:.s3m=.o) samples.o instruments.o

else
    KRAWALL_USED_NOTHING=yes
endif
endif
else

#
# not registered
#

ifeq ($(findstring .s3m,$(KRAWALL_FILES)),.s3m)

KRAWALL_USED_S3M=yes
KRAWALL_OFILES=$(KRAWALL_FILES:.s3m=.o) samples.o

else
KRAWALL_USED_NOTHING=yes
endif


endif


$(PROGNAME).elf : $(KRAWALL_OFILES) $(OFILES)
ifeq ($(KRAWALL_USED_S3M),yes) 
	@echo "-----------------------------" 
	@echo " " 
	@echo "HAM Krawall subsystem: found S3M input files."
	@echo "HAM will convert to: $(KRAWALL_OFILES)"  
	@echo "and link them into your GBA ROM. Also auto-linking Krawall lib." 
	@echo " " 
	@echo "ATTENTION: " 
	@echo " " 
	@echo "Please make sure you include the newly created modules.h and " 
	@echo "samples.h in your code, you need them to use the Krawall lib." 
	@echo " " 
	@echo "For more information about how to use Krawall, see the docs in" 
	@echo "the docs-krawall folder of your installation directory."
	@echo " " 
	@echo "-----------------------------" 
	$(LD) $(LDFLAGS) -o $(PROGNAME).elf $(OFILES) $(KRAWALL_OFILES) $(ADD_LIBS) -lkrawall $(LD_LIBS)
else
ifeq ($(KRAWALL_USED_XM),yes) 
	@echo "-----------------------------" 
	@echo " " 
	@echo "HAM Krawall subsystem: found XM input files." 
	@echo "HAM will convert to: $(KRAWALL_OFILES)"  
	@echo "and link them into your GBA ROM. Also auto-linking Krawall lib." 
	@echo " " 
	@echo "ATTENTION: " 
	@echo " " 
	@echo "Please make sure you include the newly created modules.h and " 
	@echo "samples.h in your code, you need them to use the Krawall lib." 
	@echo " " 
	@echo "For more information about how to use Krawall, see the docs in" 
	@echo "the docs-krawall folder of your intallation directory." 
	@echo " " 
	@echo "-----------------------------" 
	$(LD) $(LDFLAGS) -o $(PROGNAME).elf $(OFILES) $(KRAWALL_OFILES) $(ADD_LIBS) -lkrawall $(LD_LIBS)
else
ifeq ($(KRAWALL_USED_NOTHING),yes)
	@echo "-----------------------------" 
	@echo " " 
	@echo "HAM Krawall subsystem: found NO input files (.s3m or .xm), not linking the library." 
	@echo " " 
	@echo "-----------------------------" 
	$(LD) $(LDFLAGS) -o $(PROGNAME).elf $(OFILES) $(ADD_LIBS) $(LD_LIBS)
endif
endif
endif

else

LDFLAGS += $(ADD_LDFLAGS) $(LIBDIR) --script $(HAMDIR)/system/lnkscript-afm

$(PROGNAME).elf : $(OFILES)
	$(LD) $(LDFLAGS) -o $(PROGNAME).elf $(OFILES) $(ADD_LIBS) -lafm $(LD_LIBS)
endif 




#
# Compile Targets for C/C++
# (refined by Ulrich Hecht, thanks)
#
.s.o:
	$(AS) $(ASFLAGS) $< -o $@

.c.o:
	$(CC) $(CFLAGS) $< -o $@

.cpp.o:
	$(CC) $(CFLAGS) $< -o $@

crt0.o : $(HAMDIR)/system/crt0.s 
	$(AS) $(ASFLAGS) $(HAMDIR)/system/crt0.s -ocrt0.o

#
# Sending Targets
#

mbv2: all
	$(HAMDIR)/tools/$(HAM_PLATFORM)/mb$(EXEC_POSTFIX) -c -x 500 -w 50 -s $(PROGNAME).$(EXT)

vba: all fixheader
	$(HAMDIR)/tools/$(HAM_PLATFORM)/vba$(EXEC_POSTFIX) $(PROGNAME).$(EXT)

runvba: 
	$(HAMDIR)/tools/$(HAM_PLATFORM)/vba$(EXEC_POSTFIX) $(PROGNAME).$(EXT)

ifeq ($(HAM_PLATFORM),linux) 
gdb: all fixheader
	$(HAMDIR)/tools/$(HAM_PLATFORM)/vba$(EXEC_POSTFIX) -Gtcp &
	echo "file $(PROGNAME).elf" > insight.ini
	echo "target remote 127.0.0.1:55555" >> insight.ini
	echo "load $(PROGNAME).elf" >> insight.ini
	echo "b main" >> insight.ini
	echo "c" >> insight.ini
	$(GDB) --command=insight.ini $(PROGNAME).elf
rungdb: 
	$(HAMDIR)/tools/$(HAM_PLATFORM)/vba$(EXEC_POSTFIX) -Gtcp &
	echo "file $(PROGNAME).elf" > insight.ini
	echo "target remote 127.0.0.1:55555" >> insight.ini
	echo "load $(PROGNAME).elf" >> insight.ini
	echo "b main" >> insight.ini
	echo "c" >> insight.ini
	$(GDB) --command=insight.ini $(PROGNAME).elf
else
gdb: all fixheader
	$(HAMDIR)/tools/$(HAM_PLATFORM)/vba$(EXEC_POSTFIX) -Gtcp &
	$(HAMDIR)/tools/$(HAM_PLATFORM)/creategdb.bat $(PROGNAME).elf  
	$(GDB) --command=insight.ini $(PROGNAME).elf
rungdb: 
	$(HAMDIR)/tools/$(HAM_PLATFORM)/vba$(EXEC_POSTFIX) -Gtcp &
	$(HAMDIR)/tools/$(HAM_PLATFORM)/creategdb.bat $(PROGNAME).elf  
	$(GDB) --command=insight.ini $(PROGNAME).elf
endif

emu: all fixheader
	$(HAM_EMUPATH) $(PROGNAME).$(EXT)
runemu: 
	$(HAM_EMUPATH) $(PROGNAME).$(EXT)

fla: all fixheader
	$(HAMDIR)/tools/$(HAM_PLATFORM)/fl$(EXEC_POSTFIX) -w 50 -p $(PROGNAME).$(EXT)

runfla: 
	$(HAMDIR)/tools/$(HAM_PLATFORM)/fl$(EXEC_POSTFIX) -w 50 -p $(PROGNAME).$(EXT)

flambv2: all fixheader
	$(HAMDIR)/tools/$(HAM_PLATFORM)/mb$(EXEC_POSTFIX) -e -x 500 -w 50 -p $(PROGNAME).$(EXT)
	$(HAMDIR)/tools/$(HAM_PLATFORM)/mb$(EXEC_POSTFIX) -c -x 50

runflambv2: 
	$(HAMDIR)/tools/$(HAM_PLATFORM)/mb$(EXEC_POSTFIX) -e -x 500 -w 50 -p $(PROGNAME).$(EXT)
	$(HAMDIR)/tools/$(HAM_PLATFORM)/mb$(EXEC_POSTFIX) -c -x 50


#
# raw to object conversion, including interwork flipping
#

%.o : %.raw
	@$(LD) -A elf32-littlearm --format binary --oformat elf32-littlearm $< -o $@ -r -EL -T $(HAMDIR)/system/bin2rodata.x
	$(HAMDIR)/tools/$(HAM_PLATFORM)/elf_align$(EXEC_POSTFIX) $@ 4
	$(HAMDIR)/tools/$(HAM_PLATFORM)/interflip$(EXEC_POSTFIX) -mthumb-interwork $@
#
# XXX to raw conversion
#

%.raw : %.wav
	$(HAMDIR)/tools/$(HAM_PLATFORM)/wav2gba $< $@

%.o : %.mod
	$(LD) -A elf32-littlearm --format binary --oformat elf32-littlearm $< -o $@ -r -EL -T $(HAMDIR)/system/bin2rodata.x
	$(HAMDIR)/tools/$(HAM_PLATFORM)/elf_align$(EXEC_POSTFIX) $@ 4
	$(HAMDIR)/tools/$(HAM_PLATFORM)/interflip$(EXEC_POSTFIX) -mthumb-interwork $@
#
# Krawall s3m / XM conversion
#

%.s : %.s3m
	$(HAMDIR)/tools/$(HAM_PLATFORM)/krawall/converter $(KRAWALL_FILES)

%.s : %.xm
	$(HAMDIR)/tools/$(HAM_PLATFORM)/krawall/converter $(KRAWALL_FILES)

#
# Other Targets
#

ifeq ($(HAM_PLATFORM),linux) 
fixheader:
	cp $(PROGNAME).$(EXT)  $(PROGNAME)_tmp.$(EXT)  
	$(HAMDIR)/tools/$(HAM_PLATFORM)/ht.pl -n "$(PROGNAME)" -cl -o $(PROGNAME).$(EXT) $(PROGNAME)_tmp.$(EXT) 
	rm -f $(PROGNAME)_tmp.$(EXT)  
else
fixheader:
	$(HAMDIR)/tools/$(HAM_PLATFORM)/gbafix$(EXEC_POSTFIX) $(PROGNAME).$(EXT)  
endif


ifeq ($(HAM_PLATFORM),linux) 
clean: info
	rm -f *.o *.i *.ii
else
clean: info
	$(HAMDIR)/tools/$(HAM_PLATFORM)/rm -f *.o *.i *.ii
endif

info:
	@echo "------------------------------------------------------------------"
	@echo " HAM installation information:"
	@echo " "
	@echo " HAM version:      $(HAM_VERSION_MAJOR).$(HAM_VERSION_MINOR)"
	@echo " Installed to:     $(HAMDIR)"
	@echo " GCC version:      $(HAM_VERSION_GCC)"
	@echo " GDB version:      $(HAM_VERSION_INSIGHT)"
	@echo " Newlib version:   $(HAM_VERSION_NEWLIB)"
	@echo " Binutils version: $(HAM_VERSION_BINUTILS)"
	@echo " Krawall enabled:  $(USE_KRAWALL)"
	@echo " Krawall regged:   $(KRAWALL_IS_REGISTERED)"
	@echo "------------------------------------------------------------------"




#ifeq ($(USE_KRAWALL),yes)
#	@echo "@ dummy samples.s file" > samples.s
#	@echo "@ you should not remove this, or you might run into compiling trouble using Krawall." >> samples.s
#	@echo "@ dummy instruments.s file" > instruments.s
#	@echo "@ you should not remove this, or you might run into compiling trouble using Krawall." >> instruments.s
#else
#	rm -f samples.s
#	rm -f instruments.s
#endif

