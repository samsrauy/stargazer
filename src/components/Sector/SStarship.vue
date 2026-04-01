<template>
  <div>
    <q-expansion-item
      :icon="`img:${icon.starship()}`"
      header-class="starship-header sf-header rounded-borders q-mb-sm"
      :label="data.name"
      caption="Starship"
    >
      <controls v-if="controls" @move="$emit('move', $event)" />
      <div class="row q-gutter-sm q-mb-sm no-wrap items-baseline">
        <i-input class="col" label="Name" v-model="data.name" />
        <i-input class="col" label="Class" v-model="data.class" />
        <i-input class="col" label="Fleet" v-model="data.fleet" />
        <q-select
          v-if="$q.screen.gt.sm"
          class="col"
          label="Faction"
          v-model="faction"
          :options="campaignFactionNames"
          dense
          standout="bg-blue-grey text-white"
          :input-style="{ color: '#ECEFF4' }"
        />
        <q-btn v-if="config.data.edit" icon="delete" flat dense @click="$emit('delete')" />
      </div>

      <template v-if="$q.screen.lt.md">
        <div class="row q-gutter-sm q-mb items-baseline">
          <i-input class="col q-mb-sm" label="First Look" v-model="data.firstLook" />
          <q-select 
            class="col" 
            label="Faction" 
            v-model="faction" 
            :options="campaignFactionNames" 
            dense 
            standout="bg-blue-grey text-white" 
            :input-style="{ color: '#ECEFF4' }"
          />
        </div>
      </template>
      <template v-else>
        <i-input class="q-mb-sm" label="First Look" v-model="data.firstLook" />
      </template>

      <i-input class="q-mb-sm" label="Initial Contact" v-model="data.initialContact" />
      <i-input class="q-mb-sm" label="Mission" v-model="data.mission" />
      <i-input class="q-mb-sm" label="Notes" v-model="data.notes" autogrow />
    </q-expansion-item>
  </div>
</template>

<script lang="ts">
import { defineComponent, PropType, ref, watch, computed } from 'vue';
import { IStarship, IFaction } from '../models';
import { useConfig } from 'src/store/config';
import { useCampaign } from 'src/store/campaign';
import { icon } from 'src/lib/icons';
import Controls from './Controls.vue';
import IInput from '../Widgets/IInput.vue';

export default defineComponent({
  components: { IInput, Controls },
  name: 'SStarship',
  props: {
    modelValue: {
      type: Object as PropType<IStarship>,
      required: true,
    },
    controls: {
      type: Boolean,
    },
  },
  emits: ['update:modelValue', 'delete', 'move'],
  setup(props, { emit }) {
    const data = ref(props.modelValue);
    
    watch(
      () => props.modelValue,
      () => (data.value = props.modelValue),
      { deep: true }
    );
    watch(
      () => data.value,
      () => emit('update:modelValue', data.value),
      { deep: true }
    );

    const faction = computed({
      get() {
        // FIXED: Added fallback (?? '') to ensure string type
        return getFactionForId(data.value.factionId ?? '')?.name ?? 'None';
      },
      set(value: string) {
        if (value === 'None') {
          data.value.factionId = '';
        } else {
          const factionForSelectedName = getFactionForName(value);
          data.value.factionId = !factionForSelectedName ? '' : factionForSelectedName.id;
        }
      },
    });

    const campaignFactionNames = computed((): string[] => {
      const factionNames = useCampaign().data.factions.map((x) => x.name);
      if (factionNames.length == 0) return ['None'];
      factionNames.unshift('None');
      return factionNames;
    });

    const getFactionForName = function (factionName: string): IFaction {
      return useCampaign().data.factions.find((x) => x.name === factionName) as IFaction;
    };
    const getFactionForId = function (factionId: string): IFaction {
      return useCampaign().data.factions.find((x) => x.id === factionId) as IFaction;
    };

    if (data.value.factionId === undefined) data.value.factionId = '';

    const config = useConfig();
    return {
      data,
      config,
      icon,
      faction,
      campaignFactionNames,
      getFactionForName,
      getFactionForId,
    };
  },
});
</script>
