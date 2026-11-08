# Audit des espèces par zone : poissons non d'eau douce et portée « État » (8 nov.)

Cause : (1) les listes d'État mêlaient occurrences GBIF/NAS (Grands Lacs, saumons plantés, récifs d'Hawaï ou de Californie) et liste de l'agence ; (2) l'app retombe sur le niveau État pour tout lac sans liste propre et l'affichait comme « Liste pour tout l'État ». Correction : habitat WoRMS/FishBase (`outils/us/especes/habitat.py`, table `habitat-worms.json`), retrait des entrées non eau douce, liste d'agence seule au niveau État quand elle existe, libellé « pas propres à ce plan d'eau ».

Entrées retirées (non eau douce ou nom non résolu) : 300, dans 30 États.

| État | retirées | exemples |
|---|---|---|
| AK | 2 | Coregonus richardsonii (Coregonus richardsonii); Surf smelt (Hypomesus pretiosus) |
| AL | 7 | Swampland Longear Sunfish (Lepomis solis) |
| AR | 15 | Rio Grande Longear Sunfish (Lepomis aquilensis); Perca obscura (Perca obscura) |
| AZ | 1 | Oncorhynchus hybridus (Oncorhynchus hybridus) |
| CA | 83 | Whitebait smelt (Allosmerus elongatus); Catostomus mniotiltus (Catostomus mniotiltus); Helioperca incisor (Helioperca incisor); Surf smelt (Hypomesus pretiosus); Oncorhynchus hybridus (Oncorhynchus hybridus); Rutilus thoburni (Rutilus thoburni); Salmo evermanni (Salmo evermanni); Salmo roosevelti (Salmo roosevelti); Salmo rosei (Salmo rosei); Night smelt (Spirinchus starksi) |
| CO | 3 | Oncorhynchus hybridus (Oncorhynchus hybridus); hybrid sunfish (Lepomis) |
| FL | 1 | Swampland Longear Sunfish (Lepomis solis) |
| GA | 1 | Swampland Longear Sunfish (Lepomis solis) |
| HI | 114 | Indo-Pacific Sergeant (Abudefduf vaigiensis); lined surgeonfish (Acanthurus lineatus); Deepbody Anchovy (Anchoa compressa); a bristlenosed catfish (Ancistrus cf. temminckii); bristlenosed catfish (Ancistrus sp.); goldspotted angelfish (Apolemichthys xanthopunctatus); lemonpeel angel (Centropyge flavissima); flaming angelfish (Centropyge loricula); peacock hind (Cephalopholis argus); darkfin hind (Cephalopholis urodeta) |
| ID | 1 | Oncorhynchus hybridus (Oncorhynchus hybridus) |
| KY | 1 | Rio Grande Longear Sunfish (Lepomis aquilensis) |
| LA | 8 | Rio Grande Longear Sunfish (Lepomis aquilensis); Swampland Longear Sunfish (Lepomis solis); Tessellated Blenny (Hypsoblennius invemar); Regal Demoiselle (Neopomacentrus cyanomos); lionfish (Pterois volitans/miles) |
| ME | 2 | Coregonus stanleyi (Coregonus stanleyi) |
| MI | 3 | Leucichthys cyanopterus (Leucichthys cyanopterus); Oncorhynchus hybridus (Oncorhynchus hybridus) |
| MN | 1 | Coregonus richardsonii (Coregonus richardsonii) |
| MO | 3 | Rio Grande Longear Sunfish (Lepomis aquilensis); Perca obscura (Perca obscura) |
| MS | 8 | Rio Grande Longear Sunfish (Lepomis aquilensis); Swampland Longear Sunfish (Lepomis solis) |
| NE | 2 | Tautog (Tautoga onitis) |
| NJ | 1 | hybrid sunfish (Lepomis) |
| NM | 2 | Rio Grande Longear Sunfish (Lepomis aquilensis); Oncorhynchus hybridus (Oncorhynchus hybridus) |
| NV | 8 | Oncorhynchus hybridus (Oncorhynchus hybridus); suckermouth catfish (Hypostomus sp.); Deepbody Thread Herring (Opisthonema libertate); an African Jewelfish (Rubricatochromis sp.) |
| NY | 1 | Coregonus osmeriformis (Coregonus osmeriformis) |
| OH | 1 | Ictalurus lacustris (Ictalurus lacustris) |
| OK | 1 | Rio Grande Longear Sunfish (Lepomis aquilensis) |
| OR | 13 | Whitebait smelt (Allosmerus elongatus); Surf smelt (Hypomesus pretiosus); Oncorhynchus hybridus (Oncorhynchus hybridus); Night smelt (Spirinchus starksi); sunfish (Lepomis sp.); barred knifejaw (Oplegnathus fasciatus); great amberjack (Seriola lalandi) |
| TN | 1 | Rio Grande Longear Sunfish (Lepomis aquilensis) |
| TX | 1 | Rio Grande Longear Sunfish (Lepomis aquilensis) |
| UT | 8 | Hybrid sunfish (Lepomis spp. (hybride)); Oncorhynchus hybridus (Oncorhynchus hybridus); bristlenosed catfish (Ancistrus sp.); an African Jewelfish (Rubricatochromis sp.) |
| WA | 6 | Surf smelt (Hypomesus pretiosus); Salmo bathoecetor (Salmo bathoecetor); Salmo eremogenes (Salmo eremogenes); Night smelt (Spirinchus starksi); barred knifejaw (Oplegnathus fasciatus) |
| WY | 1 | Oncorhynchus hybridus (Oncorhynchus hybridus) |

## Liste d'État affichée à un lac sans liste propre (avant → après)

| État | avant | après | nature |
|---|---|---|---|
| WI | 89 | 23 | liste de l’agence |
| MN | 86 | 86 | occurrences d’État (GBIF/NAS), marquées comme telles |
| MI | 88 | 42 | liste de l’agence |
| TX | 116 | 116 | occurrences d’État (GBIF/NAS), marquées comme telles |
| FL | 96 | 33 | liste de l’agence |
| NY | 92 | 20 | liste de l’agence |
| CA | 197 | 197 | occurrences d’État (GBIF/NAS), marquées comme telles |

## Reste incertain
- Une espèce d'eau douce signalée à l'échelle de l'État n'est jamais prouvée dans un plan d'eau donné ; l'app le dit.
- Sans liste d'agence (MN, TX, CA), la liste d'État vient d'occurrences GBIF/NAS : Grands Lacs, disparues ou exotiques peuvent y rester (marquées « signalées dans l'État »).
- L'app ne transmet pas encore le HUC8 du lac : le niveau bassin n'est jamais utilisé (voir rapport au parent).
- Entrées sans correspondance WoRMS retirées par prudence (hybrides rares, synonymes) : peut retirer quelques vraies espèces.
