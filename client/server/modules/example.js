export const handleExample = ({ response }) => {
  console.log('hi', response);
  return new Promise((resolve, reject) => {
    if ( true ) {
      resolve(true);
    } else {
      reject("bad things happened");
    }
  });
};
