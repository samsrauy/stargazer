<template>
  <q-page padding>
    <div class="row q-gutter-sm q-mb-md" v-if="$q.screen.gt.xs">
      <q-select
        class="col-3"
        label="Sector"
        v-model="config.data.sector"
        :options="sectorOpts"
        map-options
        emit-value
        standout="bg-blue-grey text-white"
        :input-style="{ color: '#ECEFF4' }"
        dense
      />

      <q-btn class="col-shrink" flat dense icon="add_circle" @click="addSector">
        <q-tooltip>Create New Sector</q-tooltip>
      </q-btn>

      <i-input class="col" label="Sector Name" v-model="campaign.data.sectors[config.data.sector].name">
        <template v-slot:append>
          <q-btn
            round
            flat
            icon="casino"
            size="sm"
            @click="autoGenerate(campaign.data.sectors[config.data.sector], 'name')"
          />
          <q-btn
            round
            flat
            icon="auto_fix_high"
            size="sm"
            @click="autoGenerate(campaign.data.sectors[config.data.sector], 'content')"
          >
            <q-tooltip>Populate Sector</q-tooltip>
          </q-btn>
        </template>
      </i-input>

      <q-select
        class="col"
        label="Region"
        v-model="campaign.data.sectors[config.data.sector].region"
        :options="Object.values(ERegion)"
        standout="bg-blue-grey text-white"
        :input-style="{ color: '#ECEFF4' }"
        dense
      />

      <i-input class="col" label="Faction/Control" v-model="campaign.data.sectors[config.data.sector].control" />
    </div>

    <div v-else>
      <div class="row q-mb-sm">
        <q-select
          class="col"
          label="Sector"
          v-model="config.data.sector"
          :options="sectorOpts"
          map-options
          emit-value
          standout="bg-blue-grey text-white"
          :input-style="{ color: '#ECEFF4' }"
          dense
        />
        <q-btn class="col-shrink" flat dense icon="add_circle" @click="addSector" />
      </div>

      <div class="row q-gutter-sm q-mb-sm">
        <q-select
          class="col"
          label="Region"
          v-model="campaign.data.sectors[config.data.sector].region"
          :options="Object.values(ERegion)"
          standout="bg-blue-grey text-white"
          :input-style="{ color: '#ECEFF4' }"
          dense
        />
        <i-input class="col" label="Faction/Control" v-model="campaign.data.sectors[config.data.sector].control" />
      </div>
      <div class="row q-mb-sm">
        <i-input class="col" label="Sector Name" v-model="campaign.data.sectors[config.data.sector].name">
          <template v-slot:append>
            <q-btn
              round
              flat
              icon="casino"
              size="sm"
              @click="autoGenerate(campaign.data.sectors[config.data.sector], 'name')"
            />
            <q-btn
              round
              flat
              icon="auto_fix_high"
              size="sm"
              @click="autoGenerate(campaign.data.sectors[config.data.sector], 'content')"
            />
          </template>
        </i-input>
      </div>
    </div>

    <div class="row q-gutter-sm q-mb-sm">
      <q-input
        label-color="blue-grey-3"
        class="col"
        label="Search"
        v-model="searchText"
        standout="bg-blue-grey text-white"
        :input-style="{ color: '#ECEFF4' }"
        dense
      />
      <q-select
        class="col"
        label="Filters"
        v-model="filters"
        :options="Object.values(ESectorOpts)"
        standout="bg-blue-grey text-white"
        :input-style="{ color: '#ECEFF4' }"
        multiple
        dense
        use-chips
      />
    </div>

    <div class="row q-gutter-sm q-mb-sm">
      <div class="col">
        <hex-map v-if="dataReady" />
      </div>
      <div class="col-3" v-if="$q.screen.gt.sm">
        <q-scroll-area style="height: 600px">
          <div v-for="(cellData, cellID) in results[config.data.sector]" :key="cellID">
             <div class="text-subtitle2 q-pa-xs bg-blue-grey-9 text-white">{{ cellData.name || cellID }}</div>
             <cell :sectorID="config.data.sector" :cellID="String(cellID)" />
          </div>
        </q-scroll-area>
      </div>
    </div>

    <div class="row">
      <i-input
        type="textarea"
        class="col"
        label="Notes"
        v-model="campaign.data.sectors[config.data.sector].notes"
        autogrow
      />
    </div>
  </q-page>
</template>

<script lang="ts">
import { defineComponent, computed, ref, onBeforeMount } from 'vue';
import { useCampaign } from 'src/store/campaign';
import { useConfig } from 'src/store/config';
import { Notify } from 'quasar';
import { roll } from 'src/lib/oracles';

// Models
import {
  ERegion,
  ESectorOpts,
  ECellStatus,
  ISector,
  IStarship,
  INPC,
  ICreature,
  IDerelict,
  IVault,
  ISighting,
  ESLocation,
  EPClass,
  IPlanet,
  ISettlement,
  ESettPop
} from 'src/components/models';

// Libs
import { 
  NewSector, NewStar, NewPlanet, NewSettlement, 
  NewShip, NewDerelict, NewVault
} from 'src/lib/sector';

// Components
import HexMap from 'src/components/Sector/HexMap.vue';
import Cell from 'src/components/Sector/Cell.vue';
import IInput from 'src/components/Widgets/IInput.vue';

interface ISearchResults {
  [sector: number]: {
    [cell: string]: {
      // FIX: Allow both arrays (lists) and strings (name) in the index signature
      [key: string]: number[] | string; 
      name: string;
    };
  };
}

export default defineComponent({
  name: 'PageSector',
  components: { HexMap, Cell, IInput },
  setup() {
    const campaign = useCampaign();
    const config = useConfig();
    const searchText = ref('');
    const filters = ref([] as ESectorOpts[]);
    const dataReady = ref(false); 

    // --- Helpers: Enum Conversion ---

    const getPlanetClass = (text: string): EPClass => {
      const lower = text.toLowerCase();
      if (lower.includes('desert') || lower.includes('furnace')) return EPClass.Desert;
      if (lower.includes('grave')) return EPClass.Grave;
      if (lower.includes('ice')) return EPClass.Ice;
      if (lower.includes('jovian')) return EPClass.Jovian;
      if (lower.includes('jungle')) return EPClass.Jungle;
      if (lower.includes('ocean')) return EPClass.Ocean;
      if (lower.includes('rocky')) return EPClass.Rocky;
      if (lower.includes('shattered')) return EPClass.Shattered;
      if (lower.includes('tainted')) return EPClass.Tainted;
      if (lower.includes('vital')) return EPClass.Vital;
      return EPClass.Desert; 
    };

    const getPopClass = (text: string): ESettPop => {
      const lower = text.toLowerCase();
      if (lower.includes('few')) return ESettPop.Few;
      if (lower.includes('dozens')) return ESettPop.Dozens;
      if (lower.includes('hundreds')) return ESettPop.Hundreds;
      if (lower.includes('thousands')) return ESettPop.Thousands;
      return ESettPop.Few; 
    };

    // --- Sanitization ---
    const isBadData = (str: string | undefined) => {
      return !str || str.toLowerCase().includes('could not find') || str.trim() === '';
    };

    const sanitizeData = () => {
      let fixedCount = 0;
      campaign.data.sectors.forEach((sec) => {
        if (!sec.cells) return;
        Object.keys(sec.cells).forEach((k) => {
          const cell = sec.cells[k];
          
          cell.planets.forEach(p => {
             if (!Object.values(EPClass).includes(p.type)) {
               p.type = EPClass.Desert; 
               fixedCount++;
             }
          });
          
          cell.ships.forEach(s => {
             if (isBadData(s.class)) { s.class = 'Carrier'; fixedCount++; }
          });
        });
      });
      if (fixedCount > 0) console.warn(`Sanitized ${fixedCount} entries.`);
    };

    onBeforeMount(() => {
      sanitizeData();
      dataReady.value = true;
    });

    // --- Oracle Logic ---
    const safeRoll = (tableId: string, fallback = ''): string => {
      try {
        const result = roll(tableId);
        if (!result || result.toString().toLowerCase().includes('could not find oracle')) {
            return fallback;
        }
        return result;
      } catch (e) {
        return fallback; 
      }
    };

    const createEmptyCell = (key: string) => {
      return {
        id: key,
        stat: ECellStatus.Location,
        name: key, // Use Raw ID
        stars: [],
        planets: [],
        settlements: [],
        ships: [] as IStarship[],
        npcs: [] as INPC[],
        creatures: [] as ICreature[],
        derelicts: [] as IDerelict[],
        vaults: [] as IVault[],
        sightings: [] as ISighting[],
        factions: [] as string[], 
        notes: '',
      };
    };

    // --- Generators ---

    const generatePlanet = (planet: IPlanet) => {
      // 1. Class
      const rawClass = safeRoll('Starforged/Oracles/Planets/Class', 'Desert World');
      const typeKey = rawClass.replace(/[^a-z]/gi, '').replace('World', ''); 
      planet.type = getPlanetClass(typeKey);
      
      // 2. Details
      planet.name = safeRoll(`Starforged/Oracles/Planets/${typeKey}/Sample Names`, 'Unknown');
      planet.atmosphere = safeRoll(`Starforged/Oracles/Planets/${typeKey}/Atmosphere`);
      planet.observed = safeRoll(`Starforged/Oracles/Planets/${typeKey}/Observed_From_Space`);
      planet.feature = safeRoll(`Starforged/Oracles/Planets/${typeKey}/Feature`);
      planet.life = safeRoll(`Starforged/Oracles/Planets/${typeKey}/Life`);
    };

    const generateSettlement = (settlement: ISettlement, region: string) => {
      const reg = region || 'Terminus';
      
      settlement.name = safeRoll('Starforged/Oracles/Settlements/Name');
      settlement.location = safeRoll('Starforged/Oracles/Settlements/Location') as ESLocation;
      
      const rawPop = safeRoll(`Starforged/Oracles/Settlements/Population/${reg}`, 'Few');
      settlement.population = getPopClass(rawPop);

      settlement.authority = safeRoll('Starforged/Oracles/Settlements/Authority');
      settlement.projects = safeRoll('Starforged/Oracles/Settlements/Projects');
      settlement.trouble = safeRoll('Starforged/Oracles/Settlements/Trouble');
      settlement.firstLook = safeRoll('Starforged/Oracles/Settlements/First_Look');
      settlement.initialContact = safeRoll('Starforged/Oracles/Settlements/Initial_Contact');
    };

    const generateShip = (ship: IStarship) => {
      ship.name = safeRoll('Starforged/Oracles/Starships/Name');
      ship.class = safeRoll('Starforged/Oracles/Starships/Type'); 
      ship.mission = safeRoll('Starforged/Oracles/Starships/Mission');
      ship.fleet = safeRoll('Starforged/Oracles/Starships/Fleet');
    };

    const generateDerelict = (derelict: IDerelict) => {
      derelict.location = safeRoll('Starforged/Oracles/Derelicts/Location') as ESLocation;
      
      const locKey = derelict.location.replace(' ', '_');
      // eslint-disable-next-line @typescript-eslint/no-explicit-any, @typescript-eslint/no-unsafe-assignment
      derelict.type = safeRoll(`Starforged/Oracles/Derelicts/Type/${locKey}`) as any;
      
      if ((derelict.type as unknown as string) === 'Starship') { 
         derelict.name = safeRoll('Starforged/Oracles/Starships/Name');
      } else {
         derelict.name = safeRoll('Starforged/Oracles/Settlements/Name');
      }
      
      derelict.condition = safeRoll('Starforged/Oracles/Derelicts/Condition');
      derelict.outerFirstLook = safeRoll('Starforged/Oracles/Derelicts/Outer_First_Look');
    };

    const generateVault = (vault: IVault) => {
      vault.location = safeRoll('Starforged/Oracles/Vaults/Location') as ESLocation;
      vault.scale = safeRoll('Starforged/Oracles/Vaults/Scale');
      vault.form = safeRoll('Starforged/Oracles/Vaults/Form');
      vault.shape = safeRoll('Starforged/Oracles/Vaults/Shape');
      vault.material = safeRoll('Starforged/Oracles/Vaults/Material');
      vault.outerFirstLook = safeRoll('Starforged/Oracles/Vaults/Outer_First_Look');
    };

    function autoGenerate(target: ISector, type: string) {
      if (!target) return;
      
      try {
        if (type === 'name') {
          const prefix = safeRoll('Starforged/Oracles/Space/Sector_Name/Prefix', 'Alpha');
          const suffix = safeRoll('Starforged/Oracles/Space/Sector_Name/Suffix', 'Centauri');
          target.name = `${prefix} ${suffix}`;
          Notify.create({ message: `Renamed to ${target.name}`, color: 'positive' });
          return;
        } 
        
        if (type === 'content') {
          target.cells = {};
          
          let settlementCount = 2;
          if (target.region === 'Terminus') settlementCount = 4;
          else if (target.region === 'Outlands') settlementCount = 3;
          
          // 1. STAR
          const starKey = `h-${Math.floor(Math.random()*10)}-${Math.floor(Math.random()*10)}`;
          target.cells[starKey] = createEmptyCell(starKey);
          const star = NewStar();
          star.name = safeRoll('Starforged/Oracles/Space/Stellar_Object/Name', target.name + ' Prime');
          target.cells[starKey].stars.push(star);
          
          // 2. PLANETS
          const planetCount = Math.floor(Math.random() * 4) + 2;
          const planetKeys: string[] = [];
          
          for (let i = 0; i < planetCount; i++) {
            const pKey = `h-${Math.floor(Math.random()*10)}-${Math.floor(Math.random()*10)}`;
            if (!target.cells[pKey]) target.cells[pKey] = createEmptyCell(pKey);

            const planet = NewPlanet();
            generatePlanet(planet);
            if (!planet.name || planet.name === 'Unknown') planet.name = `Planet ${i+1}`;
            
            target.cells[pKey].planets.push(planet);
            planetKeys.push(pKey);
          }

          // 3. SETTLEMENTS
          if (planetKeys.length > 0) {
            for (let i = 0; i < settlementCount; i++) {
              const randomKey = planetKeys[Math.floor(Math.random() * planetKeys.length)];
              const settlement = NewSettlement();
              generateSettlement(settlement, target.region);
              target.cells[randomKey].settlements.push(settlement);
            }
          }

          // 4. EXTRAS
          // Ships
          if (Math.random() < 0.3) {
            const sKey = `h-${Math.floor(Math.random()*10)}-${Math.floor(Math.random()*10)}`;
            if (!target.cells[sKey]) target.cells[sKey] = createEmptyCell(sKey);
            try {
              if (NewShip) {
                 const ship = NewShip();
                 generateShip(ship);
                 target.cells[sKey].ships.push(ship);
              }
            } catch (e) { /* ignore */ }
          }

          // Derelicts
          if (Math.random() < 0.1) {
             const dKey = `h-${Math.floor(Math.random()*10)}-${Math.floor(Math.random()*10)}`;
             if (!target.cells[dKey]) target.cells[dKey] = createEmptyCell(dKey);
             try {
               if (NewDerelict) {
                 const derelict = NewDerelict();
                 generateDerelict(derelict);
                 target.cells[dKey].derelicts.push(derelict);
               }
             } catch(e) { /* Ignore */ }
          }

          // Vaults
          if (Math.random() < 0.05) {
             const vKey = `h-${Math.floor(Math.random()*10)}-${Math.floor(Math.random()*10)}`;
             if (!target.cells[vKey]) target.cells[vKey] = createEmptyCell(vKey);
             try {
               if (NewVault) {
                 const vault = NewVault();
                 generateVault(vault);
                 target.cells[vKey].vaults.push(vault);
               }
             } catch(e) { /* Ignore */ }
          }

          Notify.create({ message: 'Generated Sector Content', color: 'positive' });
        }
      } catch (err) {
        console.error(err);
        Notify.create({ message: 'Oracle Error', color: 'negative' });
      }
    }

    const sectorOpts = computed(() => {
      return campaign.data.sectors.map((s, i) => ({ label: s.name, value: i }));
    });

    const addSector = () => {
      campaign.data.sectors.push(NewSector());
      config.data.sector = campaign.data.sectors.length - 1;
    };

    const removeSector = () => {
      const d = config.data.sector;
      config.data.sector = 0;
      campaign.data.sectors.splice(d, 1);
    };

    const t = (s: string): boolean => {
      if (!searchText.value) return true;
      return RegExp(searchText.value, 'i').test(s);
    };

    const results = computed((): ISearchResults => {
      const res = {} as ISearchResults;
      const currentSector = campaign.data.sectors[config.data.sector];
      if (!currentSector) return res;

      Object.keys(currentSector.cells).forEach((cellI) => {
        const cell = currentSector.cells[cellI];
        if (cell.stat !== ECellStatus.Location) return;
        
        if (t(cell.name) || t(cell.notes)) {
           if (!res[config.data.sector]) res[config.data.sector] = {};
           res[config.data.sector][cellI] = { 
             [ESectorOpts.Stars]: [],
             name: cell.name 
           };
        }
      });
      return res;
    });

    return {
      campaign,
      config,
      ERegion,
      ESectorOpts,
      sectorOpts,
      addSector,
      removeSector,
      searchText,
      filters,
      results,
      autoGenerate,
      dataReady,
    };
  },
});
</script>
