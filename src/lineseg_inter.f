*dk,lineseg_inter
      subroutine lineseg_inter(x1,y1,z1,x2,y2,z2,linkt,sbox,
     &   eps,mtfound,itfound,ierr)
c
c #####################################################################
c
c     purpose -
c
c     LINESEG_INTER uses the k-D tree structure for a surface
c     (generated by KDTREE) to accelerate finding all intersections of
c     the surface with the given line segment [(X1,Y1,Z1),(X2,Y2,Z2)].
c     What is actually returned is a small subset of leaves
c     (i.e., triangles) that feasibly could intersect the line
c     segment.  The user must then do exact geometric tests on this
c     small subset to actually determine points of intersection.
c
c     input arguments -
c
c         x1,y1,z1,  -   coordinates of points defining the
c         x2,y2,z2       line segment
c         linkt,sbox -   k-D tree arrays.
c         eps  -         epsilon for length comparisons.
c
c     output arguments -
c         mtfound -      no. of leaves (triangles) returned
c         itfound -      array of triangles returned
c         ierr -         error return.
c
c     change history -
c
c         $log$
 
      implicit none
      include 'consts.h'
 
      real*8 x1,y1,z1,x2,y2,z2,sbox(2,3,1000000),eps
      integer linkt(1000000),mtfound,itfound(1000000),ierr
 
      integer istack(100)
 
      integer itop,node,ind,i,k,iord(2,3)
      real*8 x(2,3),sdim(3),rmin,rmax,s(2)
 
      mtfound=0
 
c.... Load two endpoints of line segment into array X.
 
      x(1,1)=x1
      x(2,1)=x2
      x(1,2)=y1
      x(2,2)=y2
      x(1,3)=z1
      x(2,3)=z2
 
c.... Loop thru x, y, and z directions (i=1,2,3, respectively)
c.... and define the permutation IORD so that X(IORD(1,i),i) <
c.... X(IORD(2,i),i).  We perturb the endpoints of the
c.... segment (if necessary) so that they have a projection on
c.... the three coordinate axes of at least EPS.
 
      do i=1,3
         if (x(1,i).le.x(2,i)) then
            if (x(2,i)-x(1,i).lt.eps) then
               x(1,i)=x(1,i)-eps*0.5
               x(2,i)=x(2,i)+eps*0.5
            endif
            iord(1,i)=1
            iord(2,i)=2
         else
            if (x(1,i)-x(2,i).lt.eps) then
               x(1,i)=x(1,i)+eps*0.5
               x(2,i)=x(2,i)-eps*0.5
            endif
            iord(1,i)=2
            iord(2,i)=1
         endif
         sdim(i)=x(2,i)-x(1,i)
      enddo
 
c.... If the minimum line segment coordinate is greater than the
c.... maximum bounding box coordinate, or conversely, if the
c.... maximum line segment coordinate is less than the minimum
c.... bounding box coordinate, there is no intersection.
 
      do i=1,3
         if (x(iord(1,i),i).gt.sbox(2,i,1)+2*eps) goto 9999
         if (x(iord(2,i),i).lt.sbox(1,i,1)-2*eps) goto 9999
      enddo
 
c.... If root node is a leaf, return leaf.
 
      if (linkt(1).lt.0) then
         mtfound=1
         itfound(1)=-linkt(1)
         goto 9999
      endif
 
      itop=1
      istack(itop)=1
 
c.... Traverse (relevant part of) k-D tree using stack
 
      do while (itop.gt.0)
 
c.... pop node off of stack
 
         node=istack(itop)
         itop=itop-1
 
         ind=linkt(node)
 
c.... check if either child of NODE is a leaf or should be
c.... put on stack.
 
         do 10 k=0,1
 
c.... If child is a leaf, add triangle to triangle list
 
            if (linkt(ind+k).lt.0) then
               mtfound=mtfound+1
               itfound(mtfound)=-linkt(ind+k)
            else
 
c.... For each of the x,y, and z directions, project the
c.... ``safety box'' of the node onto the one-dimensional
c.... subspace spanned by the line segment.
c.... (The parameter for the one-dimensional subspace has
c.... by convention a value of zero at one endpoint and
c.... a value of one at the other endpoint.)  After obtaining
c.... three such intervals of projection, we conclude the
c.... line segment intersects the box if and only if
c.... the three intervals have nonempty intersection which
c.... includes some point in [0,1].  If so, put this node
c.... on the stack.
c....
c.... We perform all tests involving bounding boxes which are
c.... 2*EPS inflated.  This is because (i) to be safe we need
c.... to check if our ORIGINAL line segment intersects
c.... with an EPS-inflated bounding box, and (ii) the possible
c.... EPS/2 perturbations in each coordinate direction of the
c.... line segment endpoints imply that the line segment of
c.... testing differs from the ORIGINAL line segment by at most
c.... SQRT(3)*EPS/2 < EPS.  Taking (i) and (ii) together, we
c.... should test against ``2*EPS''-inflated boxes.
 
               rmin=0.
               rmax=1.
 
               do i=1,3
                  s(1)=sbox(1,i,ind+k)-2*eps
                  s(2)=sbox(2,i,ind+k)+2*eps
                  rmin=max(rmin,(s(iord(1,i))-x(1,i))/sdim(i))
                  rmax=min(rmax,(s(iord(2,i))-x(1,i))/sdim(i))
                  if (rmax.lt.rmin) goto 10
               enddo
               itop=itop+1
               istack(itop)=ind+k
 
            endif
 10      continue
      enddo
 
 9999 continue
      return
      end
