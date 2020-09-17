import { NativeModules } from 'react-native';

type BoostlingoType = {
  multiply(a: number, b: number): Promise<number>;
};

const { Boostlingo } = NativeModules;

export default Boostlingo as BoostlingoType;
