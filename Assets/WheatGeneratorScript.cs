using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WheatGeneratorScript : MonoBehaviour 
{
    public Color HighColor;
    public Color LowColor;
    public Color DistanceColor;
    [Range(0, 1)]
    public float CardWidth;
    [Range(0, 1)]
    public float CardHeight;

    public int WheatStalks;
    public Material WheatMat;
    public Material GroundPlaneMat;
    public ComputeShader WheatCompute;
    public Texture2D Noise;

    public Transform EffectorSphere;

    public float EffectorOuterRadius;
    public float EffectorInnerRadius;
    public float EffectorVelocityImpact;
    public float WindSpeed;
    public float WindIntensity;
    public float VelocityDecay;
    public float StalkStiffness;

    private ComputeBuffer fixedDataBuffer;
    private ComputeBuffer variableDataBuffer;
    private int wheatComputeKernel;
    private const int computeThreadCount = 128;
    private int groupsToDispatch;

    struct FixedWheatData
    {
        public Vector2 PlanePos;
        public Vector2 PlaneTangent;
    }

    struct VariableWheatData
    {
        public Vector3 StalkNormal;
        public Vector2 PlanarVelocity;
    }

    private const int FixedDataStride = sizeof(float) * 2 + sizeof(float) * 2;
    private const int VariableDataStride = sizeof(float) * 3 + sizeof(float) * 2;

    void Start () 
    {
        fixedDataBuffer = GetFixedDataBuffer();
        variableDataBuffer = GetVariableDataBuffer();
        wheatComputeKernel = WheatCompute.FindKernel("WheatCompute");
        groupsToDispatch = Mathf.CeilToInt((float)WheatStalks / computeThreadCount);
    }

    private void Update()
    {
        WheatCompute.SetBuffer(wheatComputeKernel, "_FixedDataBuffer", fixedDataBuffer);
        WheatCompute.SetBuffer(wheatComputeKernel, "_VariableDataBuffer", variableDataBuffer);
        WheatCompute.SetTexture(wheatComputeKernel, "_Noise", Noise);
        WheatCompute.SetFloat("_Time", Time.fixedTime);
        Vector3 relativeEffector = transform.worldToLocalMatrix * EffectorSphere.position;
        WheatCompute.SetVector("_EffectorPos", relativeEffector);

        WheatCompute.SetFloat("_EffectorOuterRadius", EffectorOuterRadius);
        WheatCompute.SetFloat("_EffectorInnerRadius", EffectorInnerRadius);
        WheatCompute.SetFloat("_EffectorVelocityImpact", EffectorVelocityImpact);
        WheatCompute.SetFloat("_WindSpeed", WindSpeed);
        WheatCompute.SetFloat("_WindIntensity", WindIntensity);
        WheatCompute.SetFloat("_VelocityDecay", VelocityDecay);
        WheatCompute.SetFloat("_StalkStiffness", StalkStiffness);

        WheatCompute.Dispatch(wheatComputeKernel, groupsToDispatch, 1, 1);

        GroundPlaneMat.SetVector("_EffectorPos", EffectorSphere.position);
        GroundPlaneMat.SetColor("_LowColor", LowColor);
        GroundPlaneMat.SetColor("_DistanceColor", DistanceColor);
    }

    private ComputeBuffer GetVariableDataBuffer()
    {
        ComputeBuffer ret = new ComputeBuffer(WheatStalks, VariableDataStride);
        VariableWheatData[] data = new VariableWheatData[WheatStalks];
        for (int i = 0; i < WheatStalks; i++)
        {
            data[i] = new VariableWheatData() { StalkNormal = Vector3.up };
        }
        ret.SetData(data);
        return ret;
    }

    private Vector2 GetPlaneTangent()
    {
        Vector2 ret = new Vector2(UnityEngine.Random.value * 2 - 1, UnityEngine.Random.value * 2 - 1);
        if(ret.sqrMagnitude < float.Epsilon)
        {  
            //Rejecting this one and trying again since it can't be normalized
            return GetPlaneTangent();
        }
        return ret.normalized;
    }

    private ComputeBuffer GetFixedDataBuffer()
    { 
        ComputeBuffer ret = new ComputeBuffer(WheatStalks, FixedDataStride);
        FixedWheatData[] data = new FixedWheatData[WheatStalks];
        for (int i = 0; i < WheatStalks; i++)
        {
            Vector2 planePos = new Vector2(UnityEngine.Random.value, UnityEngine.Random.value);
            Vector2 planeTangent = GetPlaneTangent();
            data[i] = new FixedWheatData() { PlanePos = planePos , PlaneTangent = planeTangent};
        }
        ret.SetData(data);
        return ret;
    }

    private void OnDestroy()
    {
        fixedDataBuffer.Release();
        variableDataBuffer.Release();
    }

    private void OnRenderObject()
    {
        WheatMat.SetBuffer("_FixedDataBuffer", fixedDataBuffer);
        WheatMat.SetBuffer("_VariableDataBuffer", variableDataBuffer);
        WheatMat.SetColor("_HighColor", HighColor);
        WheatMat.SetColor("_LowColor", LowColor);
        WheatMat.SetColor("_DistanceColor", DistanceColor);
        WheatMat.SetFloat("_CardHeight", CardHeight);
        WheatMat.SetFloat("_CardWidth", CardWidth);
        WheatMat.SetVector("_PlayspaceScale", new Vector2(transform.localScale.x / 2, transform.localScale.z / 2));
        WheatMat.SetVector("_EffectorPos", EffectorSphere.position);
        WheatMat.SetPass(0);
        Graphics.DrawProcedural(MeshTopology.Points, 1, WheatStalks);
    }
}
