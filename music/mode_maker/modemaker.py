
# Plan

# version one is notes only 
# version two is note times and playback??

# Static data to store the scales
# Static data to store the mode flat modifier

# data to store the final scale you are using (apply mode to scale)
# data to store the original theme - as solfa (with a way of multiple octaves (going outside a single octave))

# temporary final theme data (solfa turned into notes)

# Add note to theme function -> add a solfa note to the theme sequence

# create modal_scale -> notes
# a transposer function - takes the theme and a modal scale -> notes "Get theme function"

###

# import scales and modes as json

# dataclass NoteSequence - holds a dictionary of notes with octave number as a string/enum

# var ModalScale[NoteSeq] - hold the current scale that you're using. It would hold a reference to a Scale and a Mode instance, and could have a method to apply the mode to the key.
# var Theme[NoteSeq] - hold your solfa-based theme - appending a number to each note (e.g., 'do1', 're1', 'mi2' for do-re-mi where mi is an octave higher)

# functions - Transpose(themeseq, modalscale) -> noteseq 
#           - CreateModalScale(scale, mode) -> noteseq
#           - 

from dataclasses import dataclass
from typing import List

@dataclass 
class Note():
    value: str = None
    octave: int = 1

class NoteSequence():
    Notes: List[Note] = []

    def add(self, note: Note) -> None:
        self.Notes.append(note)

    def print(self) -> None:
        for note in self.Notes:
            print(note.value, note.octave)

notes = NoteSequence()

newNote = Note(value="mi")

notes.add(newNote)
notes.print()
