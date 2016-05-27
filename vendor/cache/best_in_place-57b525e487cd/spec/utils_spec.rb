# encoding: utf-8

describe BestInPlace::Utils do
  include BestInPlace::Utils
  describe '#build_best_in_place_id' do
    it 'build id from symbol' do
      expect(build_best_in_place_id(:user, :login)).to eq('best_in_place_user_login')
    end

      it 'build id from record' do
        car = Cuca::Car.create
        expect(build_best_in_place_id(car, :model)).to eq("best_in_place_cuca_car_#{car.id}_model")
      end


  end

  describe '#object_to_key' do

  end
end