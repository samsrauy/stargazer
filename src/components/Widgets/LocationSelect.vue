<template>
  <div class="row items-center">
    <div class="col">
      <div class="row">
        <q-select
          class="col-grow"
          label="Sector"
          v-model="sectorSelect"
          :options="sOpts"
          map-options
          emit-value
          borderless
          dense
        />
        <q-select
          class="col-grow"
          label="Cell"
          v-model="cellSelect"
          :options="cOpts"
          map-options
          emit-value
          borderless
          dense
        />
      </div>
    </div>
    <q-btn :icon="icon" flat dense @click="$emit('selected', { sector: sectorSelect, cell: cellSelect })" />
  </div>
</template>

<script lang="ts">
import { defineComponent, computed, ref, watch } from 'vue';

import { ECellStatus, ISelectOpt } from '../models';
import { useCampaign } from 'src/store/campaign';
import { useConfig } from 'src/store/config';

export default defineComponent({
  name: 'LocationSelect',
  props: {
    icon: {
      type: String,
      default: 'save',
    },
  },
  emits: ['selected'],
  setup() {
    const campaign = useCampaign();
    const config = useConfig();

    // Default to 0 if the config sector index is invalid
    const initialSector = campaign.data.sectors[config.data.sector] ? config.data.sector : 0;
    const sectorSelect = ref(initialSector);

    const sOpts = computed((): ISelectOpt[] => {
      const opts: ISelectOpt[] = [];
      campaign.data.sectors.forEach((s, si) => {
        opts.push({
          label: s.name,
          value: si,
        });
      });
      return opts;
    });

    const cellSelect = ref(null);
    
    const cOpts = computed((): ISelectOpt[] => {
      const opts: ISelectOpt[] = [];
      
      const currentSector = campaign.data.sectors[sectorSelect.value];
      if (!currentSector || !currentSector.cells) {
        return [{ label: 'Loading...', value: '' }];
      }

      Object.keys(currentSector.cells).forEach((id) => {
        if (currentSector.cells[id].stat === ECellStatus.Location) {
          // Use the Name if it exists (including raw ID set by generator), otherwise fallback to key
          const label = currentSector.cells[id].name || id;
          opts.push({
            label: label,
            value: id,
          });
        }
      });
      
      if (opts.length === 0) {
        opts.push({
          label: 'Create a location first',
          value: '',
        });
      }
      return opts;
    });

    // Reset cell selection when sector changes to prevent stale data
    watch(sectorSelect, () => {
      cellSelect.value = null;
    });

    return {
      campaign,
      config,
      sectorSelect,
      sOpts,
      cellSelect,
      cOpts,
      ECellStatus,
    };
  },
});
</script>
