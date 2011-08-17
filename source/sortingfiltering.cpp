IMatchModel *model = ...; // een model

model->sort("error", Qt::AscendingOrder); // alles moet gesorteerd worden op het "error" attribuut, van laag naar hoog
model->filter(
	"duplicates_filter", 
	"duplicate = 0"
); // eis dat het "duplicaat"-attribuut van een paar gelijk is aan 0, wat betekent dat het geen duplicaten heeft
model->filter(
	"probability_filter", 
	"probability > 0.8 OR volume < old_volume"
); // de probabiliteit moet groter zijn dan 0.8 of het volume moet kleiner zijn dan het oude volume
model->filter(
	"my_new_status_filter", 
	"status IN (1,2)"
); // het paar moet reeds "goedgekeurd" of "waarschijnlijk goed" zijn 

...

int max = model->size(); // de hoeveelheid paren die aan de filters voldoen

for (int i = 0; i < model->size(); ++i) {
	IFragmentPair &pair = model->get(i);
	
	// doe iets met het paar
}
