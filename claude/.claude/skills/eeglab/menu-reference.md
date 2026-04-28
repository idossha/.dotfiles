# EEGLAB Menu-to-Function Reference

## File Menu
| Menu Item | Function |
|-----------|----------|
| Load existing dataset | `pop_loadset` |
| Save current dataset(s) | `pop_saveset` |
| Import data from file | `pop_fileio`, `pop_biosig`, `pop_importdata` |
| Import events | `pop_importevent` |
| Import epoch info | `pop_importepoch` |
| Export data to text | `pop_export` |
| Preferences | `pop_editoptions` |
| Import BIDS dataset | `pop_importbids` (EEG-BIDS plugin) |

## Edit Menu
| Menu Item | Function |
|-----------|----------|
| Dataset info | `pop_editset` |
| Channel locations | `pop_chanedit` |
| Event fields | `pop_editeventfield` |
| Event values | `pop_editeventvals` |
| Select data (channels/time) | `pop_select` |
| Select data using events | `pop_rmdat` |
| Select epochs or events | `pop_selectevent` |
| Append datasets | `pop_mergeset` |

## Tools Menu (Preprocessing)
| Menu Item | Function |
|-----------|----------|
| Change sampling rate | `pop_resample` |
| Basic FIR filter (legacy) | `pop_eegfilt` |
| FIR filter (firfilt plugin) | `pop_eegfiltnew` |
| Re-reference | `pop_reref` |
| Interpolate electrodes | `pop_interp` |
| Inspect/reject by eye | `pop_eegplot` |
| Automatic channel rejection | `pop_rejchan` |
| Automatic continuous rejection | `pop_rejcont` |
| Automatic epoch rejection | `pop_autorej` |
| Decompose data by ICA | `pop_runica` |
| Remove components from data | `pop_subcomp` |
| Extract epochs | `pop_epoch` |
| Remove epoch baseline | `pop_rmbase` |
| Clean Rawdata and ASR | `pop_clean_rawdata` (plugin) |
| Classify components ICLabel | `pop_iclabel` (plugin) |
| Flag components as artifacts | `pop_icflag` (plugin) |

## Epoch Rejection Tools
| Menu Item | Function |
|-----------|----------|
| Reject extreme values | `pop_eegthresh` |
| Reject by linear trend/variance | `pop_rejtrend` |
| Reject by probability | `pop_jointprob` |
| Reject by kurtosis | `pop_rejkurt` |
| Reject by spectra | `pop_rejspec` |

## Plot Menu
| Menu Item | Function |
|-----------|----------|
| Channel data (scroll) | `pop_eegplot` |
| Channel spectra and maps | `pop_spectopo` |
| Channel properties | `pop_prop` |
| Channel ERP image | `pop_erpimage` |
| Channel ERPs with scalp maps | `pop_timtopo` |
| ERP map series (2-D) | `pop_topoplot` |
| ERP map series (3-D) | `pop_headplot` |
| Component activations (scroll) | `pop_eegplot` (with ICA data) |
| Component spectra and maps | `pop_spectopo` (with ICA) |
| Component maps (2-D) | `pop_topoplot` (with ICA) |
| Component properties | `pop_prop` (with ICA) |
| Component ERPs | `pop_envtopo` |
| Time-frequency | `pop_newtimef` |

## STUDY Menu (Multi-Subject)
| Menu Item | Function |
|-----------|----------|
| Create STUDY (loaded datasets) | `pop_study` |
| Browse for datasets | `pop_studywizard` |
| Simple ERP STUDY | `pop_studyerp` |
| Load/Save STUDY | `pop_loadstudy` / `pop_savestudy` |
| Edit STUDY design | `pop_studydesign` |
| Pre-compute statistics | `pop_precomp` |
| Pre-cluster components | `pop_preclust` |
| Cluster components | `pop_clust` |
